package MCat::Model::Page;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE NUL TRUE );
use HTTP::Status           qw( HTTP_OK );
use JSON::MaybeXS          qw( encode_json );
use MCat::Util             qw( create_token new_uri redirect );
use Type::Utils            qw( class_type );
use Unexpected::Functions  qw( PageNotFound UnauthorisedAccess
                               UnknownToken UnknownUser );
use MCat::Redis;
use Try::Tiny;
use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'page';

has 'redis' => is => 'lazy', isa => class_type('MCat::Redis'), default => sub {
   my $self = shift;

   return MCat::Redis->new(
      client_name => $self->config->prefix . '_job_stash',
      config => $self->config->redis
   );
};

# TODO: Show/hide password on change password

sub base : Auth('none') {
   my ($self, $context, $id_or_name) = @_;

   $self->_stash_user($context, $id_or_name);
   $context->stash('nav')->finalise;
   return;
}

sub access_denied : Auth('none') {}

sub changes : Auth('none') Nav('Changes') {
   my ($self, $context) = @_;

   $context->stash(form => $self->new_form('Changes', { context => $context }));
   return;
}

sub default : Auth('none') {
   my ($self, $context) = @_;

   my $default = $context->uri_for_action($self->config->redirect);

   $context->stash(redirect $default, []);
   return;
}

sub login : Auth('none') Nav('Login') {
   my ($self, $context) = @_;

   my $params = $context->get_body_parameters;

   if ($params->{_submit} && $params->{_submit} eq 'password_reset') {
      $self->_stash_user($context, $params->{name});
      $self->password_reset($context);
      return;
   }

   if ($params->{_submit} && $params->{_submit} eq 'totp_reset') {
      $context->stash(redirect $context->uri_for_action(
         'page/totp_reset', [$params->{name}, 'reset']
      ), []);
      return;
   }

   my $options = { context => $context, log => $self->log };
   my $form    = $self->new_form('Login', $options);

   if ($form->process( posted => $context->posted )) {
      my $name     = $form->field('name')->value;
      my $default  = $context->uri_for_action($self->config->redirect);
      my $wanted   = $context->session->wanted;
      my $location = new_uri $context->request->scheme, $wanted if $wanted;
      my $message  = 'User [_1] logged in';

      $context->stash(redirect $location || $default, [$message, $name]);
      $context->session->wanted(NUL);
   }

   $context->stash( form => $form );
   return;
}

sub logout : Auth('view') Nav('Logout') {
   my ($self, $context) = @_;

   return unless $self->verify_form_post($context);

   my $default = $context->uri_for_action('page/login');
   my $message = 'User [_1] logged out';
   my $session = $context->session;

   $session->authenticated(FALSE);
   $session->role(NUL);
   $session->wanted(NUL);
   $context->stash(redirect $default, [$message, $session->username]);
   return;
}

sub not_found : Auth('none') {
   my ($self, $context) = @_;

   return $self->error($context, PageNotFound, [$context->request->path]);
}

sub object_property : Auth('none') {
   my ($self, $context) = @_;

   my $req   = $context->request;
   my $class = $req->query_params->('class');
   my $prop  = $req->query_params->('property');
   my $value = $req->query_params->('value', { raw => TRUE });
   my $body  = { found => \0 };

   if ($value) {
      try { # Defensively written
         my $r = $context->model($class)->find_by_key($value);

         $body->{found} = \1 if $r && $r->execute($prop);
      }
      catch { $self->log->error($_, $context) };
   }

   $context->stash(body => encode_json($body), code => HTTP_OK, view => 'json');
   return;
}

sub password : Auth('none') Nav('Change Password') {
   my ($self, $context) = @_;

   my $user    = $context->stash('user') or return;
   my $options = { context => $context, item => $user, log => $self->log };
   my $form    = $self->new_form('ChangePassword', $options);

   if ($form->process( posted => $context->posted )) {
      my $default = $context->uri_for_action($self->config->redirect);
      my $message = 'User [_1] changed password';

      $context->stash(redirect $default, [$message, $form->item->name]);
   }

   $context->stash(form => $form);
   return;
}

sub password_reset : Auth('none') {
   my ($self, $context, $userid, $token) = @_;

   my $user    = $context->stash('user') or return;
   my $changep = $context->uri_for_action('page/password', [$user->id]);

   if (!$context->posted && $token && $token ne 'reset') {
      my $stash = $self->redis->get($token)
         or return $self->error($context, UnknownToken, [$token]);

      $user->update({password => $stash->{password}, password_expired => TRUE});

      my $message = 'User [_1] password reset';

      $context->stash(redirect $changep, [$message, "${user}"]);
      $self->redis->remove($token);
      return;
   }

   return unless $context->posted;
   return unless $self->verify_form_post($context);

   unless ($user->can_email) {
      my $login   = $context->uri_for_action('page/login');
      my $message = 'User [_1] no email address';

      $context->stash(redirect $login, [$message, "${user}"]);
      return;
   }

   $token = create_token;

   my $actionp = 'page/password_reset';
   my $link    = $context->uri_for_action($actionp, [$user->id, $token]);
   my $passwd  = substr create_token, 0, 12;
   my $options = {
      application => $self->config->name,
      link        => "${link}",
      password    => $passwd,
      recipients  => [$user->id],
      subject     => 'Password Reset',
      template    => 'password_reset.md',
   };
   my $job     = $self->_send_email($context, $token, $options);
   my $message = 'User [_1] password reset request [_2] dispatched';

   $context->stash(redirect $changep, [$message, "${user}", $job->label]);
   return;
}

sub register : Auth('none') Nav('Register') {
   my ($self, $context, $token) = @_;

   return $self->error($context, UnauthorisedAccess)
      unless $self->config->registration;

   return $self->_create_user($context, $token)
      if !$context->posted && $token;

   my $form = $self->new_form('Register', {
      context => $context, log => $self->log, redis => $self->redis
   });

   if ($form->process( posted => $context->posted )) {
      my $job     = $context->stash->{job};
      my $login   = $context->uri_for_action('page/login');
      my $message = 'Registration request [_1] dispatched';

      $context->stash(redirect $login, [$message, $job->label]);
      return;
   }

   $context->stash(form => $form);
   return;
}

sub totp_reset : Auth('none') {
   my ($self, $context, $userid, $token) = @_;

   my $user = $context->stash('user') or return;

   if (!$context->posted && $token && $token ne 'reset') {
      my $stash = $self->redis->get($token)
         or return $self->error($context, UnknownToken, [$token]);
      my $options = { context => $context, user => $user };

      $context->stash(form => $self->new_form('TOTP::Secret', $options));
      $self->redis->remove($token);
      return;
   }

   my $form = $self->new_form('TOTP::Reset', {
      context => $context,
      log     => $self->log,
      redis   => $self->redis,
      user    => $user
   });

   if ($form->process( posted => $context->posted )) {
      my $job     = $context->stash->{job};
      my $message = 'User [_1] TOTP reset request [_2] dispatched';
      my $login   = $context->uri_for_action('page/login');

      $context->stash(redirect $login, [$message, "${user}", $job->label]);
   }

   $context->stash(form => $form);
   return;
}

# Private methods
sub _create_user {
   my ($self, $context, $token) = @_;

   my $stash = $self->redis->get($token)
      or return $self->error($context, UnknownToken, [$token]);
   my $role  = $context->model('Role')->find({ name => 'view' });
   my $args  = {
      email            => $stash->{email},
      name             => $stash->{username},
      password         => $stash->{password},
      password_expired => TRUE,
      role_id          => $role->id,
   };
   my $user    = $context->model('User')->create($args);
   my $changep = $context->uri_for_action('page/password', [$user->id]);
   my $message = 'User [_1] created';

   $context->stash(redirect $changep, [$message, $user->name]);
   $self->redis->remove($token);
   return;
}

sub _send_email {
   my ($self, $context, $token, $args) = @_;

   $self->redis->set($token, encode_json($args));

   my $program = $self->config->bin->catfile('mcat-cli');
   my $command = "${program} -o token=${token} send_message email";
   my $options = { command => $command, name => 'send_message' };

   return $context->model('Job')->create($options);
}

sub _stash_user {
   my ($self, $context, $id_or_name) = @_;

   return unless $id_or_name;

   $id_or_name = { name => $id_or_name } unless $id_or_name =~ m{ \A \d+ \z }mx;

   my $user = $context->model('User')->find($id_or_name)
      or return $self->error($context, UnknownUser, [$id_or_name]);

   $context->stash( user => $user );
   return;
}

1;
