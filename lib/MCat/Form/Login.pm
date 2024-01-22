package MCat::Form::Login;

use HTML::Forms::Constants qw( FALSE META TRUE );
use MCat::Util             qw( redirect );
use Scalar::Util           qw( blessed );
use Unexpected::Functions  qw( catch_class );
use Try::Tiny;
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms';
with    'HTML::Forms::Role::Defaults';

has '+name'         => default => 'Login';
has '+title'        => default => 'Login';
has '+info_message' => default => 'Enter your user name and password';
has '+item_class'   => default => 'User';

my $change_js = q{HForms.Util.fieldChange('login', '%s')};

has_field 'name' =>
   html_name    => 'user_name',
   input_param  => 'user_name',
   label        => 'User Name',
   required     => TRUE,
   tags         => { label_tag => 'span' },
   title        => 'Enter your user name or email address',
   toggle       => { -set => ['password_reset'] },
   toggle_event => 'onblur';

has_field 'password' =>
   type         => 'Password',
   element_attr => {
      javascript => 'onblur="' . sprintf($change_js, 'password') . '"'
   },
   tags         => { label_tag => 'span' },
   required     => TRUE;

has_field 'auth_code' =>
   type          => 'Digits',
   element_attr => {
      javascript => 'onblur="' . sprintf($change_js, 'auth_code') . '"'
   },
   label         => 'Auth. Code',
   size          => 6,
   tags          => { label_tag => 'span' },
   title         => 'Enter the Authenticator code',
   wrapper_class => ['input-integer'];

has_field 'login' =>
   type          => 'Button',
   disabled      => TRUE,
   element_attr  => { 'data-field-depends' => [qw(user_name password)] },
   html_name     => 'submit',
   label         => 'Login',
   value         => 'login',
   wrapper_class => ['input-button expand'];

my $button_js = q{onclick="HForms.Util.unrequire(['auth_code', 'password'])"};

has_field 'password_reset' =>
   type          => 'Button',
   html_name     => 'submit',
   element_attr  => { javascript => $button_js },
   label         => 'Forgot Password?',
   title         => 'Send password reset email',
   value         => 'password_reset',
   wrapper_class => ['input-button expand'];

has_field 'totp_reset' =>
   type          => 'Button',
   html_name     => 'submit',
   element_attr  => { javascript => $button_js },
   label         => 'Reset Auth.',
   title         => 'Request a TOTP reset',
   value         => 'totp_reset',
   wrapper_class => ['input-button expand'];

around 'after_build_fields' => sub {
   my ($orig, $self) = @_;

   $orig->($self);

   $self->set_form_element_attr('novalidate', 'novalidate');

   my $session = $self->context->session;

   unless ($session->enable_2fa) {
      push @{$self->field('auth_code')->wrapper_class}, 'hide';
      push @{$self->field('totp_reset')->wrapper_class}, 'hide';
   }

   unless ($session->id) {
      push @{$self->field('password_reset')->wrapper_class}, 'hide';
   }

   my $method = 'HForms.Util.showIfRequired';
   my $uri    = $self->context->uri_for_action('page/object_property', [], {
      class => 'User', property => 'enable_2fa'
   });
   my $showif = "${method}('${uri}', 'user_name', ['auth_code', 'totp_reset'])";

   $method = 'HForms.Toggle.toggleFields';

   my $toggle = "${method}(document.getElementById('user_name'))";
   my $change = sprintf $change_js, 'user_name';
   my $attr   = $self->field('name')->element_attr;

   $attr->{javascript} = qq{onblur="${toggle}; ${showif}; ${change}"};
   return;
};

around 'validate_form' => sub {
   my ($orig, $self) = @_;

   my @modified_fields;

   if (my $field_obj = $self->field('auth_code')) {
      $field_obj->required(FALSE);
      push @modified_fields, $field_obj;
   }

   $orig->($self);

   $_->required(TRUE) for (@modified_fields);

   return;
};

sub validate {
   my $self = shift;

   return if $self->result->has_errors;

   my $context = $self->context;
   my $name    = $self->field('name');
   my ($username, $realm) = reverse split m{ : }mx, $name->value;
   my $options = { prefetch => ['profile', 'role'] };
   my $args    = { username => $username, options => $options };
   my $user    = $context->find_user($args, $realm);

   return $name->add_error('User [_1] unknown', $username) unless $user;

   my $passwd  = $self->field('password');
   my $code    = $self->field('auth_code');

   $args = { user => $user, password => $passwd->value, code => $code->value };

   try {
      $context->logout;
      $context->authenticate($args, $realm);
      $context->set_authenticated($args, $realm);
   }
   catch_class $self->_handlers($user, $passwd, $code);

   return;
}

# Private methods
sub _handlers {
   my ($self, $user, $passwd, $code) = @_;

   my $context = $self->context;

   return [
      'IncorrectAuthCode' => sub { $code->add_error($_->original) },
      'IncorrectPassword' => sub { $passwd->add_error($_->original) },
      'PasswordExpired'   => sub {
         my $changep = $context->uri_for_action('page/password', [$user->id]);

         $context->stash(redirect $changep, [$_->original]);
         $context->stash('redirect')->{level} = 'alert' if $self->has_log;
      },
      'Authentication' => sub { $self->add_form_error($_->original) },
      'Unspecified'    => sub { $self->add_form_error($_->original) },
      '*' => sub {
         $self->add_form_error(blessed $_ ? $_->original : "${_}");
         $self->log->alert($_, $context) if $self->has_log;
      }
   ];
}

use namespace::autoclean -except => META;

1;
