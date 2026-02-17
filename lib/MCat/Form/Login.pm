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
   html_name    => '__user_name',
   input_param  => '__user_name',
   label        => 'User Name',
   label_top    => TRUE,
   required     => TRUE,
   title        => 'Enter your user name or email address';

has_field 'password' =>
   type         => 'Password',
   autocomplete => TRUE,
   html_name    => '__password',
   input_param  => '__password',
   label_top    => TRUE,
   required     => TRUE,
   title        => 'Enter your password';

has_field 'auth_code' =>
   type          => 'Digits',
   html_name     => '__auth_code',
   input_param   => '__auth_code',
   label         => 'OTP Code',
   label_top     => TRUE,
   size          => 6,
   title         => 'Enter the Authenticator code',
   wrapper_class => ['input-integer'];

has_field 'login' =>
   type          => 'Button',
   disabled      => TRUE,
   element_attr  => { 'data-field-depends' => [qw(__user_name __password)] },
   html_name     => 'submit',
   label         => 'Submit',
   value         => 'login';

has_field 'register' =>
   type          => 'Link',
   element_attr  => { 'data-field-depends' => ['!__user_name'] },
   element_class => ['form-button'],
   label         => 'Sign Up',
   title         => 'Register for a login account',
   wrapper_class => ['input-button'];

has_field 'password_reset' =>
   type          => 'Button',
   disabled      => TRUE,
   element_attr  => { 'data-field-depends' => ['__user_name'] },
   html_name     => 'submit',
   label         => 'Password Reset',
   title         => 'Send password reset email',
   value         => 'password_reset';

has_field 'totp_reset' =>
   type          => 'Button',
   disabled      => TRUE,
   element_attr  => { 'data-field-depends' => ['__user_name'] },
   html_name     => 'submit',
   label         => 'OTP Reset',
   title         => 'Request an OTP reset',
   value         => 'totp_reset';

my $change_flds = [qw(login register password_reset totp_reset)];
my $showif_flds = ['__auth_code','totp_reset'];
my $unreq_flds  = ['__auth_code', '__password'];

after 'after_build_fields' => sub {
   my $self    = shift;
   my $context = $self->context;
   my $config  = $context->config;
   my $session = $context->session;

   $self->set_form_element_attr('novalidate', 'novalidate');

   $self->add_form_element_class('radar')
      if includes 'radar', $session->features;

   if (defined $session->enable_2fa && !$session->enable_2fa) {
      $self->field('auth_code')->add_wrapper_class('hide');
      $self->field('totp_reset')->add_wrapper_class('hide');
   }

   if (includes 'droplets', $session->features) {
      $self->add_form_element_class('droplets');
      $self->field('register')->add_wrapper_class('droplet');
      $self->field('password_reset')->add_wrapper_class('droplet');
      $self->field('totp_reset')->add_wrapper_class('droplet');

      my $action = $config->default_actions->{register};
      my $uri    = $context->uri_for_action($action);

      $self->field('register')->href($uri->as_string);
   }
   else {
      for my $field_name (@{$change_flds}) {
         $self->field($field_name)->add_wrapper_class('expand');
      }

      $self->field('register')->inactive(TRUE);
   }

   $self->field('register')->inactive(TRUE) unless $config->registration;

   $self->_add_field_handlers;
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

   return unless $self->validated;

   my ($username, $realm) = $self->_get_realm;

   my $context = $self->context;
   my $options = { prefetch => ['profile', 'role'] };
   my $args    = { username => $username, options => $options };
   my $user    = $context->find_user($args, $realm);
   my $name    = $self->field('name');

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
sub _add_field_handlers {
   my $self      = shift;
   my $context   = $self->context;
   my $config    = $context->config;
   my $util      = $config->wcom_resources->{form_util};
   my $change_js = "${util}.fieldChange";
   my $showif_js = "${util}.showIfRequired";
   my $unreq_js  = "${util}.unrequire";

   my $action  = $config->default_actions->{fetch};
   my $params  = { class => 'User', property => 'enable_2fa' };
   my $uri     = $context->uri_for_action($action, ['property'], $params);
   my $options = { id => '__user_name', url => "${uri}" };
   my $handler = make_handler($showif_js, $options, $showif_flds);

   $self->field('name')->add_handler('blur', $handler);
   $handler = make_handler($change_js, { id => '__user_name' }, $change_flds);
   $self->field('name')->add_handler('input', $handler);

   $handler = make_handler($change_js, { id => '__password' }, $change_flds);
   $self->field('password')->add_handler('input', $handler);

   $handler = make_handler($change_js, { id => '__auth_code' }, $change_flds);
   $self->field('auth_code')->add_handler('blur', $handler);

   $handler = make_handler($unreq_js, { allow_default => TRUE }, $unreq_flds);
   $self->field('password_reset')->add_handler('click', $handler);

   $handler = make_handler($unreq_js, { allow_default => TRUE }, $unreq_flds);
   $self->field('totp_reset')->add_handler('click', $handler);
   return;
}

sub _exception_handlers {
   my ($self, $user, $passwd, $code) = @_;

   my $context = $self->context;

   return [
      'IncorrectAuthCode' => sub { $self->add_form_error($_->original) },
      'IncorrectPassword' => sub { $self->add_form_error($_->original) },
      'InvalidIPAddress'  => sub {
         $self->add_form_error($_->original);
         $self->log->alert($_->original, $context) if $self->has_log;
      },
      'PasswordExpired'   => sub {
         my $action  = $self->config->default_actions->{password};
         my $changep = $context->uri_for_action($action, [$user->id]);

         $passwd->add_error($_->original);
         $context->stash(redirect $changep, [$_->original]);
         $context->stash('redirect')->{level} = 'alert' if $self->has_log;
      },
      'Authentication' => sub { $self->add_form_error($_->original) },
      'RedirectToAuth' => sub {
         my $params = { http_headers => { 'X-Force-Reload' => 'true' }};

         $self->add_form_error($_->original);
         $context->stash(redirect $_->args->[0], [$_->original], $params);
      },
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

sub _get_realm {
   my $self = shift;

   my ($username, $realm) = reverse split m{ : }mx, $self->field('name')->value;

   $realm = 'OAuth' if $realm && $realm eq 'oauth';
   $realm = 'OAuth' if $self->field('password')->value eq 'oauth';

   return ($username, $realm);
}

use namespace::autoclean -except => META;

1;
