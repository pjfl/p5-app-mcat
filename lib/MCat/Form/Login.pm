package MCat::Form::Login;

use HTML::Forms::Constants qw( FALSE META NUL TRUE );
use HTML::Forms::Util      qw( make_handler );
use Class::Usul::Cmd::Util qw( includes );
use MCat::Util             qw( redirect );
use Scalar::Util           qw( blessed );
use Unexpected::Functions  qw( catch_class );
use Try::Tiny;
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms';
with    'HTML::Forms::Role::Defaults';

has '+info_message' => default => 'Stop! You have your papers?';
has '+item_class'   => default => 'User';
has '+name'         => default => 'Login';
has '+title'        => default => 'Sign In';

has_field 'name' =>
   autocomplete => TRUE,
   html_name    => 'user_name',
   input_param  => 'user_name',
   label        => 'User Name',
   label_top    => TRUE,
   required     => TRUE,
   title        => 'Enter your user name or email address';

has_field 'password' =>
   type         => 'Password',
   autocomplete => TRUE,
   label_top    => TRUE,
   required     => TRUE,
   title        => 'Enter your password';

has_field 'auth_code' =>
   type          => 'Digits',
   label         => 'OTP Code',
   label_top     => TRUE,
   size          => 6,
   title         => 'Enter the Authenticator code',
   wrapper_class => ['input-integer'];

has_field 'login' =>
   type          => 'Button',
   disabled      => TRUE,
   element_attr  => { 'data-field-depends' => [qw(user_name password)] },
   html_name     => 'submit',
   label         => 'Submit',
   value         => 'login';

has_field 'register' =>
   type          => 'Link',
   element_attr  => { 'data-field-depends' => ['!user_name'] },
   element_class => ['form-button'],
   label         => 'Sign Up',
   title         => 'Register for a login account',
   wrapper_class => ['input-button'];

has_field 'password_reset' =>
   type          => 'Button',
   allow_default => TRUE,
   disabled      => TRUE,
   element_attr  => { 'data-field-depends' => ['user_name'] },
   html_name     => 'submit',
   label         => 'Password Reset',
   title         => 'Send password reset email',
   value         => 'password_reset';

has_field 'totp_reset' =>
   type          => 'Button',
   disabled      => TRUE,
   element_attr  => { 'data-field-depends' => ['user_name'] },
   html_name     => 'submit',
   label         => 'OTP Reset',
   title         => 'Request an OTP reset',
   value         => 'totp_reset';

after 'after_build_fields' => sub {
   my $self    = shift;
   my $context = $self->context;
   my $config  = $context->config;
   my $session = $context->session;

   $self->set_form_element_attr('novalidate', 'novalidate');

   if (defined $session->enable_2fa && !$session->enable_2fa) {
      $self->field('auth_code')->add_wrapper_class('hide');
      $self->field('totp_reset')->add_wrapper_class('hide');
   }

   my $util        = $config->wcom_resources->{form_util};
   my $change_js   = "${util}.fieldChange";
   my $showif_js   = "${util}.showIfRequired";
   my $unreq_js    = "${util}.unrequire";
   my $change_flds = [qw(login register password_reset totp_reset)];
   my $showif_flds = ['auth_code','totp_reset'];
   my $unreq_flds  = ['auth_code', 'password'];

   my $action  = $config->default_actions->{fetch};
   my $params  = { class => 'User', property => 'enable_2fa' };
   my $uri     = $context->uri_for_action($action, ['property'], $params);
   my $options = { id => 'user_name', url => "${uri}" };
   my $handler = make_handler($showif_js, $options, $showif_flds);

   $self->field('name')->add_handler('blur', $handler);
   $handler = make_handler($change_js, { id => 'user_name' }, $change_flds);
   $self->field('name')->add_handler('input', $handler);

   $handler = make_handler($change_js, { id => 'password' }, $change_flds);
   $self->field('password')->add_handler('input', $handler);

   $handler = make_handler($change_js, { id => 'auth_code' }, $change_flds);
   $self->field('auth_code')->add_handler('blur', $handler);

   $handler = make_handler($unreq_js, { allow_default => TRUE }, $unreq_flds);
   $self->field('password_reset')->add_handler('click', $handler);

   $handler = make_handler($unreq_js, { allow_default => TRUE }, $unreq_flds);
   $self->field('totp_reset')->add_handler('click', $handler);

   $action = $config->default_actions->{register};
   $uri    = $context->uri_for_action($action);
   $self->field('register')->href($uri->as_string);

   if (includes 'droplets', $session->features) {
      $self->add_form_element_class('droplets');
      $self->field('register')->add_wrapper_class('droplet');
      $self->field('password_reset')->add_wrapper_class('droplet');
      $self->field('totp_reset')->add_wrapper_class('droplet');
   }
   else {
      $self->field('register')->inactive(TRUE);

      for my $field_name (@{$change_flds}) {
         $self->field($field_name)->add_wrapper_class('expand');
      }
   }

   $self->add_form_element_class('radar')
      if includes 'radar', $session->features;

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

   return if !$self->validated;

   my $context = $self->context;
   my $name    = $self->field('name');
   my ($username, $realm) = reverse split m{ : }mx, $name->value;
   my $options = { prefetch => ['profile', 'role'] };
   my $args    = { username => $username, options => $options };
   my $user    = $context->find_user($args, $realm);

   return $name->add_error('User [_1] unknown', $username) unless $user;

   my $passwd  = $self->field('password');
   my $code    = $self->field('auth_code');

   $args = {
      address  => $context->request->remote_address,
      code     => $code->value,
      password => $passwd->value,
      user     => $user,
   };

   try {
      $context->logout;
      $context->authenticate($args, $realm);
      $context->set_authenticated($args, $realm);
   }
   catch_class $self->_exception_handlers($user, $passwd, $code);

   return;
}

# Private methods
sub _exception_handlers {
   my ($self, $user, $passwd, $code) = @_;

   my $context = $self->context;

   return [
      'IncorrectAuthCode' => sub { $code->add_error($_->original) },
      'IncorrectPassword' => sub { $passwd->add_error($_->original) },
      'InvalidIPAddress'  => sub {
         $self->add_form_error($_->original);
         $self->log->alert($_->original, $context) if $self->has_log;
      },
      'PasswordExpired'   => sub {
         my $action  = $self->config->default_actions->{password};
         my $changep = $context->uri_for_action($action, [$user->id]);

         $context->stash(redirect $changep, [$_->original]);
         $context->stash('redirect')->{level} = 'alert' if $self->has_log;
      },
      'Authentication' => sub { $self->add_form_error($_->original) },
      'Unspecified'    => sub {
         if ($_->args->[0] eq 'Password') { $passwd->add_error($_->original) }
         else { $code->add_error($_->original) }
      },
      '*' => sub {
         $self->add_form_error(blessed $_ ? $_->original : "${_}");
         $self->log->alert($_, $context) if $self->has_log;
      },
   ];
}

use namespace::autoclean -except => META;

1;
