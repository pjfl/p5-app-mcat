package MCat::Form::Login;

use HTML::Forms::Constants qw( FALSE META TRUE );
use MCat::Util             qw( redirect );
use Unexpected::Functions  qw( catch_class );
use Try::Tiny;
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms';
with    'HTML::Forms::Role::Defaults';

has '+title'               => default => 'Login';
has '+default_wrapper_tag' => default => 'fieldset';
has '+do_form_wrapper'     => default => TRUE;
has '+info_message'        => default => 'Enter your username and password';
has '+is_html5'            => default => TRUE;
has '+item_class'          => default => 'User';

has 'log' => is => 'ro', predicate => 'has_log';

has_field 'name' =>
   label        => 'User Name',
   required     => TRUE,
   title        => 'Enter your user name',
   toggle       => { -set => ['password_reset'] },
   toggle_event => 'onblur';

has_field 'password' => type => 'Password', required => TRUE;

has_field 'auth_code' =>
   type          => 'PosInteger',
   label         => 'Auth. Code',
   required      => TRUE,
   title         => 'Enter the Google Authenticator code',
   wrapper_class => ['hide input-integer'];

has_field 'login' =>
   type          => 'Button',
   html_name     => 'submit',
   label         => 'Login',
   value         => 'login',
   wrapper_class => ['inline input-button right'];

my $button_js = q{onclick="HForms.Util.unrequire(['auth_code', 'password'])"};

has_field 'password_reset' =>
   type          => 'Button',
   html_name     => 'submit',
   element_attr  => { javascript => $button_js },
   label         => 'Forgot Password?',
   title         => 'Send password reset email',
   value         => 'password_reset',
   wrapper_class => ['hide inline input-button'];

has_field 'totp_reset' =>
   type          => 'Button',
   html_name     => 'submit',
   element_attr  => { javascript => $button_js },
   label         => 'Reset Auth.',
   title         => 'Request a TOTP reset',
   value         => 'totp_reset',
   wrapper_class => ['hide inline input-button'];

around 'after_build_fields' => sub {
   my ($orig, $self) = @_;

   $orig->($self);

   my $method = 'HForms.Util.showIfRequired';
   my $uri    = $self->context->uri_for_action('page/object_property', [], {
      class => 'User', property => 'enable_2fa'
   });
   my $showif = "${method}('${uri}', 'name', ['auth_code', 'totp_reset'])";
   my $toggle = "HForms.Toggle.toggleFields(document.getElementById('name'))";
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
      $user->authenticate_optional_2fa($passwd->value, $code->value);
      $session->authenticated(TRUE);
      $session->id($user->id);
      $session->role($user->role->name);
      $session->username($user->name);
   }
   catch_class [
      'IncorrectAuthCode' => sub { $code->add_error($_->original) },
      'PasswordExpired' => sub {
         my $message = $_->original;
         my $changep = $context->uri_for_action('page/password', [$user->id]);

         $context->stash( redirect $changep, [$message] );
         $context->stash('redirect')->{level} = 'alert' if $self->has_log;
         $passwd->add_error($message);
      },
      'Authentication' => sub { $passwd->add_error($_->original) },
      'Unspecified' => sub { $code->add_error($_->original) },
      '*' => sub {
         $self->add_form_error(["${_}"]);
         $self->log->alert($_, $self->context) if $self->has_log;
      }
   ];

   if ($session->authenticated) {
      my $profile = $user->profile ? $user->profile->value : {};

      $session->enable_2fa($profile->{enable_2fa} ? TRUE : FALSE);
      $session->skin($profile->{skin}) if defined $profile->{skin};
      $session->timezone($profile->{timezone}) if defined $profile->{timezone};
   }

   return;
}

use namespace::autoclean -except => META;

1;
