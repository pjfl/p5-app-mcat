package MCat::Model::Misc;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE NUL TRUE );
use HTTP::Status           qw( HTTP_OK );
use MCat::Util             qw( create_token new_uri redirect );
use Type::Utils            qw( class_type );
use Unexpected::Functions  qw( PageNotFound UnauthorisedAccess
                               UnknownToken UnknownUser );
use Moo;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';
with    'MCat::Role::Redis';
with    'MCat::Role::JSONParser';

has '+moniker' => default => 'misc';

has '+redis_client_name' => is => 'ro', default => 'job_stash';

sub base : Auth('none') {
   my ($self, $context) = @_;

   $context->stash('nav')->finalise;
   return;
}

sub user : Auth('none') Capture(1) {
   my ($self, $context, $arg) = @_;

   $self->_stash_user($context, $arg);
   $context->stash('nav')->finalise;
   return;
}

sub changes : Auth('view') Nav('Changes') {
   my ($self, $context) = @_;

   $context->stash(form => $self->new_form('Changes', { context => $context }));
   return;
}

sub contact : Auth('none') Nav('Contact') {
   my ($self, $context) = @_;

   return;
}

sub create_user : Auth('none') {
   my ($self, $context, $token) = @_;

   my $stash = $self->redis_client->get($token);

   return $self->error($context, UnknownToken, [$token]) unless $stash;

   $self->redis_client->remove($token);

   my $user = $context->model('User')->create({
      email            => $stash->{email},
      name             => $stash->{username},
      password         => $stash->{password},
      password_expired => TRUE,
      role_id          => $stash->{role_id},
   });
   my $action  = $self->config->default_actions->{password};
   my $changep = $context->uri_for_action($action, [$user->id]);

   $context->stash(redirect $changep, ['User [_1] created', "${user}"]);
   return;
}

sub default : Auth('none') {
   my ($self, $context) = @_;

   my $action  = $self->config->default_actions->{get};
   my $default = $context->uri_for_action($action);

   $context->stash(redirect $default, ['Redirecting to [_1]', $default]);
   return;
}

sub footer : Auth('none') {
   my ($self, $context, $moniker, $method) = @_;

   my $session   = $context->session;
   my $templates = $context->views->{html}->templates;

   $context->stash(page => { layout => 'site/footer' });

   my $action = "${moniker}/footer";
   my $footer = $templates->catdir($session->skin)->catfile("${action}.tt");

   $context->stash(page => { layout => $action }) if $footer->exists;

   $action = "${moniker}/${method}_footer";
   $footer = $templates->catdir($session->skin)->catfile("${action}.tt");

   $context->stash(page => { layout => $action }) if $footer->exists;
   return;
}

sub login : Auth('none') Nav('Sign In') {
   my ($self, $context) = @_;

   my $options = { context => $context, log => $self->log };
   my $form    = $self->new_form('Login', $options);

   if ($form->process(posted => $context->posted)) {
      my $action   = $self->config->default_actions->{get};
      my $default  = $context->uri_for_action($action);
      my $name     = $context->session->username;
      my $wanted   = $context->session->wanted;
      my $location = new_uri $context->request->scheme, $wanted if $wanted;
      my $address  = $context->request->remote_address;
      my $message  = 'User [_1] logged in';

      $self->log->info("Address ${address}", $context);
      $context->stash(redirect $location || $default, [$message, $name]);
      $context->session->wanted(NUL);
   }

   $context->stash(form => $form);
   return;
}

sub login_dispatch : Auth('none') {
   my ($self, $context) = @_;

   my $user = $context->body_parameters->{__user_name};

   if ($context->button_pressed eq 'password_reset') {
      $self->password_reset($context) if $self->_stash_user($context, $user);
   }
   elsif ($context->button_pressed eq 'totp_reset') {
      my $reset = $context->uri_for_action('misc/totp_reset', [$user]);

      $context->stash(redirect $reset, ['Redirecting to OTP reset']);
   }
   elsif ($user) { $context->stash(forward => 'misc/login') }
   else { $context->stash(forward => 'misc/not_found') }

   return;
}

sub logout : Auth('view') Nav('Logout') {
   my ($self, $context) = @_;

   return unless $self->verify_form_post($context);

   my $action  = $self->config->default_actions->{login};
   my $login   = $context->uri_for_action($action);
   my $args    = ['User [_1] logged out', $context->session->username];
   my $options = { http_headers => { 'X-Force-Reload' => 'true' }};

   $context->logout;
   $context->stash(redirect $login, $args, $options);
   return;
}

sub not_found : Auth('none') Nav('Not Found') {
   my ($self, $context) = @_;

   $context->stash('nav')->finalise;

   return if $context->stash->{finalised};

   return $self->error($context, PageNotFound, [$context->request->path]);
}

sub password : Auth('none') Nav('Change Password') {
   my ($self, $context) = @_;

   my $user    = $context->stash('user');
   my $options = { context => $context, item => $user, log => $self->log };
   my $form    = $self->new_form('ChangePassword', $options);

   if ($form->process(posted => $context->posted)) {
      my $action  = $self->config->default_actions->{get};
      my $default = $context->uri_for_action($action);
      my $message = 'User [_1] changed password';

      $context->stash(redirect $default, [$message, "${user}"]);
   }

   $context->stash(form => $form);
   return;
}

sub password_reset : Auth('none') {
   my ($self, $context) = @_;

   $context->action('misc/password_reset');

   return unless $self->verify_form_post($context);

   my $user = $context->stash('user');

   unless ($user->can_email) {
      my $action  = $self->config->default_actions->{login};
      my $login   = $context->uri_for_action($action);
      my $message = 'User [_1] no email address';

      $context->stash(redirect $login, [$message, "${user}"]);
      return;
   }

   my $job     = $self->_create_reset_email($context, $user);
   my $action  = $self->config->default_actions->{password};
   my $changep = $context->uri_for_action($action, [$user->id]);
   my $message = 'User [_1] password reset request [_2] created';

   $context->stash(redirect $changep, [$message, "${user}", $job->label]);
   return;
}

sub password_update : Auth('none') {
   my ($self, $context, $token) = @_;

   my $stash = $self->redis_client->get($token);

   return $self->error($context, UnknownToken, [$token]) unless $stash;

   $self->redis_client->remove($token);

   my $user = $context->stash('user');

   $user->update({ password => $stash->{password}, password_expired => TRUE });

   my $action  = $self->config->default_actions->{password};
   my $changep = $context->uri_for_action($action, [$user->id]);
   my $message = 'User [_1] password reset and expired';

   $context->stash(redirect $changep, [$message, "${user}"]);
   return;
}

sub register : Auth('none') Nav('Sign Up') {
   my ($self, $context) = @_;

   return $self->error($context, UnauthorisedAccess)
      unless $self->config->registration;

   my $options = { context => $context, log => $self->log };
   my $form    = $self->new_form('Register', $options);

   if ($form->process(posted => $context->posted)) {
      my $job     = $context->stash->{job};
      my $action  = $self->config->default_actions->{login};
      my $login   = $context->uri_for_action($action);
      my $message = 'Registration request [_1] created';

      $context->stash(redirect $login, [$message, $job->label]);
      return;
   }

   $context->stash(form => $form);
   return;
}

sub totp : Auth('none') {
   my ($self, $context, $token) = @_;

   return $self->error($context, UnknownToken, [$token])
      unless $self->redis_client->get($token);

   $self->redis_client->remove($token);

   my $options = { context => $context, user => $context->stash('user') };

   $context->stash(form => $self->new_form('TOTP::Secret', $options));
   return;
}

sub totp_reset : Auth('none') {
   my ($self, $context) = @_;

   my $user    = $context->stash('user');
   my $options = { context => $context, log => $self->log, user => $user };
   my $form    = $self->new_form('TOTP::Reset', $options);

   if ($form->process(posted => $context->posted)) {
      my $job     = $context->stash->{job};
      my $action  = $self->config->default_actions->{login};
      my $login   = $context->uri_for_action($action);
      my $message = 'User [_1] OTP reset request [_2] created';

      $context->stash(redirect $login, [$message, "${user}", $job->label]);
   }

   $context->stash(form => $form);
   return;
}

sub unauthorised : Auth('none') {
   my ($self, $context) = @_;

   $self->error($context, UnauthorisedAccess);
   return;
}

# Private methods
sub _create_reset_email {
   my ($self, $context, $user) = @_;

   my $token   = create_token;
   my $actionp = 'misc/password_reset';
   my $link    = $context->uri_for_action($actionp, [$user->id, $token]);
   my $passwd  = substr create_token, 0, 12;
   my $params  = {
      application => $self->config->name,
      link        => "${link}",
      password    => $passwd,
      recipients  => [$user->id],
      subject     => 'Password Reset',
      template    => 'password_reset.md',
   };

   $self->redis_client->set($token, $self->json_parser->encode($params));

   my $prefix  = $self->config->prefix;
   my $program = $self->config->bin->catfile("${prefix}-cli");
   my $command = "${program} -o token=${token} send_message email";
   my $options = { command => $command, name => 'send_message' };

   return $context->model('Job')->create($options);
}

sub _stash_user {
   my ($self, $context, $id_or_name) = @_;

   my $realm = $context->session->realm;
   my $user  = $context->find_user({ username => $id_or_name }, $realm);

   return $self->error($context, UnknownUser, [$id_or_name]) unless $user;

   $context->stash(user => $user);
   return TRUE;
}

1;
