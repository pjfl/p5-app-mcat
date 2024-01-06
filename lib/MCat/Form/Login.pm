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

has '+title'        => default => 'Login';
has '+info_message' => default => 'Enter your username and password';
has '+item_class'   => default => 'User';

has_field 'name' =>
   html_name    => 'user_name',
   input_param  => 'user_name',
   label        => 'User Name',
   required     => TRUE,
   title        => 'Enter your user name',
   toggle       => { -set => ['password_reset'] },
   toggle_event => 'onblur';

has_field 'password' => type => 'Password', required => TRUE;

has_field 'auth_code' =>
   type          => 'Digits',
   label         => 'Auth. Code',
   required      => TRUE,
   size          => 6,
   title         => 'Enter the Authenticator code',
   wrapper_class => ['input-integer'];

has_field 'login' =>
   type          => 'Button',
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
      push @{$self->field('password_code')->wrapper_class}, 'hide';
   }

   my $method = 'HForms.Util.showIfRequired';
   my $uri    = $self->context->uri_for_action('page/object_property', [], {
      class => 'User', property => 'enable_2fa'
   });
   my $showif = "${method}('${uri}', 'user_name', ['auth_code', 'totp_reset'])";

   $method = 'HForms.Toggle.toggleFields';

   my $toggle = "${method}(document.getElementById('user_name'))";
   my $field  = $self->field('name');
   my $attr   = $field->element_attr;

   $attr->{javascript} = qq{onblur="${toggle}; ${showif}"};
   $field->element_attr($attr);
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

   my $field   = $self->field('name');
   my $name    = $field->value;
   my $context = $self->context;
   my $session = $context->session;
   my $user    = $context->model($self->item_class)->find({ name => $name });

   return $field->add_error('User [_1] unknown', $name) unless $user;

   my $passwd  = $self->field('password');
   my $code    = $self->field('auth_code');

   try {
      $session->authenticated(FALSE);
      $user->authenticate($passwd->value, $code->value);
      $session->authenticated(TRUE);
      $session->id($user->id);
      $session->role($user->role->name);
      $session->username($user->name);
   }
   catch_class [
      'IncorrectAuthCode' => sub { $code->add_error($_->original) },
      'IncorrectPassword' => sub { $passwd->add_error($_->original) },
      'PasswordExpired' => sub {
         my $message = $_->original;
         my $changep = $context->uri_for_action('page/password', [$user->id]);

         $context->stash( redirect $changep, [$message] );
         $context->stash('redirect')->{level} = 'alert' if $self->has_log;
         $passwd->add_error($message);
      },
      'Unspecified' => sub { $self->add_form_error($_->original) },
      'Authentication' => sub { $self->add_form_error($_->original) },
      '*' => sub {
         $self->add_form_error(blessed $_ ? $_->original : "${_}");
         $self->log->alert($_, $self->context) if $self->has_log;
      }
   ];

   if ($session->authenticated) {
      my $profile = $user->profile ? $user->profile->value : {};

      $session->enable_2fa($profile->{enable_2fa} ? TRUE : FALSE);
      $session->link_display($profile->{link_display})
         if defined $profile->{link_display};
      $session->menu_location($profile->{menu_location})
         if defined $profile->{menu_location};
      $session->skin($profile->{skin}) if defined $profile->{skin};
      $session->theme($profile->{theme}) if defined $profile->{theme};
      $session->timezone($profile->{timezone}) if defined $profile->{timezone};
   }

   return;
}

use namespace::autoclean -except => META;

1;
