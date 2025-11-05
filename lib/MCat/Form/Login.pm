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
has '+info_message' => default => 'Stop! You have your papers?';
has '+item_class'   => default => 'User';
has '+title'        => default => 'Login';

has_field 'name' =>
   html_name   => 'user_name',
   input_param => 'user_name',
   label       => 'User Name',
   label_top   => TRUE,
   required    => TRUE,
   title       => 'Enter your user name or email address';

has_field 'password' =>
   type      => 'Password',
   label_top => TRUE,
   required  => TRUE;

has_field 'auth_code' =>
   type          => 'Digits',
   label         => 'Auth. Code',
   label_top     => TRUE,
   size          => 6,
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

has_field 'password_reset' =>
   type          => 'Button',
   disabled      => TRUE,
   element_attr  => { 'data-field-depends' => ['user_name'] },
   html_name     => 'submit',
   label         => 'Forgot Password?',
   title         => 'Send password reset email',
   value         => 'password_reset',
   wrapper_class => ['input-button expand'];

has_field 'totp_reset' =>
   type          => 'Button',
   disabled      => TRUE,
   element_attr  => { 'data-field-depends' => ['user_name'] },
   html_name     => 'submit',
   label         => 'Reset Auth.',
   title         => 'Request a TOTP reset',
   value         => 'totp_reset',
   wrapper_class => ['input-button expand'];

after 'after_build_fields' => sub {
   my $self = shift;

   $self->set_form_element_attr('novalidate', 'novalidate');

   my $context = $self->context;
   my $session = $context->session;

   if (defined $session->enable_2fa && !$session->enable_2fa) {
      $self->field('auth_code')->add_wrapper_class('hide');
      $self->field('totp_reset')->add_wrapper_class('hide');
   }

   my $util          = $context->config->wcom_resources->{form_util};
   my $change_fields = "['login', 'password_reset', 'totp_reset']";
   my $change_js     = "${util}.fieldChange('%s', ${change_fields})";
   my $unrequire_js  = "${util}.unrequire(['auth_code', 'password'])";
   my $showif        = "${util}.showIfRequired";

   my $action  = 'api/object_fetch';
   my $params  = { class => 'User', property => 'enable_2fa' };
   my $uri     = $context->uri_for_action($action, ['property'], $params);
   my $show_js = "${showif}('user_name', ['auth_code','totp_reset'], '${uri}')";
   my $blur_js = "${show_js}; " . sprintf $change_js, 'user_name';
   my $attr    = $self->field('name')->element_attr;

   $attr->{javascript} = { onblur => $blur_js };

   $attr = $self->field('password')->element_attr;
   $attr->{javascript} = { oninput => sprintf $change_js, 'password' };

   $attr = $self->field('auth_code')->element_attr;
   $attr->{javascript} = { onblur => sprintf $change_js, 'auth_code' };

   $attr = $self->field('password_reset')->element_attr;
   $attr->{javascript} = { onclick => $unrequire_js };

   $attr = $self->field('totp_reset')->element_attr;
   $attr->{javascript} = { onclick => $unrequire_js };
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
