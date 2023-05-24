package MCat::Model::Page;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE NUL TRUE );
use HTTP::Status           qw( HTTP_OK );
use JSON::MaybeXS          qw( encode_json );
use MCat::Util             qw( create_token new_uri redirect );
use Type::Utils            qw( class_type );
use Unexpected::Functions  qw( PageNotFound UnknownToken UnknownUser );
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
      client_name => 'job_stash', config => $self->config->redis
   );
};

sub base : Auth('none') {
   my ($self, $context, $id_or_name) = @_;

   $self->_stash_user($context, $id_or_name);
   $context->stash('nav')->finalise;
   return;
}

sub access_denied : Auth('none') {}

sub default : Auth('none') {
   my ($self, $context) = @_;

   my $default = $context->uri_for_action($self->config->redirect);

   $context->stash( redirect $default, [] );
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
      $context->stash( redirect $context->uri_for_action(
         'page/totp_reset', [$params->{name}, 'reset']
      ), [] );
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

      $context->stash( redirect $location || $default, [$message, $name] );
      $context->session->wanted(NUL);
   }

   $context->stash( form => $form );
   return;
}

sub logout : Auth('view') Nav('Logout') {
   my ($self, $context) = @_;

   return unless $self->has_valid_token($context);

   my $default = $context->uri_for_action('page/login');
   my $message = 'User [_1] logged out';
   my $session = $context->session;

   $session->authenticated(FALSE);
   $session->role(NUL);
   $session->wanted(NUL);
   $context->stash( redirect $default, [$message, $session->username] );
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
   my ($self, $context, $userid) = @_;

   my $form = $self->new_form('ChangePassword', {
      context => $context, item => $context->stash('user'), log => $self->log
   });

   if ($form->process( posted => $context->posted )) {
      my $default = $context->uri_for_action($self->config->redirect);
      my $message = 'User [_1] changed password';

      $context->stash( redirect $default, [$message, $form->item->name]);
   }

   $context->stash( form => $form );
   return;
}

sub password_reset : Auth('none') {
   my ($self, $context, $userid, $token) = @_;

   my $user = $context->stash('user') or return;

   if (!$context->posted && $token && $token ne 'reset') {
      if (my $stash = $self->redis->get($token)) {
         $self->redis->remove($token);
         $user->update({
            password => $stash->{password}, password_expired => TRUE
         });

         my $changep = $context->uri_for_action('page/password', [$user->id]);
         my $message = 'User [_1] password reset';

         $context->stash(redirect $changep, [$message, "${user}"]);
         return;
      }
      else {
         return $self->error($context, UnknownToken, [$token]);
      }
   }

   return unless $context->posted;
   return unless $self->has_valid_token($context);

   unless ($user->can_email) {
      my $login   = $context->uri_for_action('page/login');
      my $message = 'User [_1] no email address';

      $context->stash(redirect $login, [$message, "${user}"]);
      return;
   }

   $token = create_token;

   my $passwd = substr create_token, 0, 12;
   my $link   = $context->uri_for_action(
      'page/password_reset', [$user->id, $token]
   );

   $self->redis->set($token, encode_json({
      application => $self->config->name,
      link        => "${link}",
      password    => $passwd,
      recipients  => [$user->id],
      subject     => 'Password Reset',
      template    => 'password_reset.tt',
   }));

   my $program = $self->config->bin->catfile('mcat-cli');
   my $command = "${program} -o token=${token} send_message email";
   my $options = { command => $command, name => 'send_message' };
   my $job     = $context->model('Job')->create($options);
   my $login   = $context->uri_for_action('page/login');
   my $message = 'User [_1] password reset request sent [_2]';

   $context->stash(redirect $login, [$message, "${user}", $job->label]);
   return;
}

sub totp_reset : Auth('none') {
   my ($self, $context, $userid, $token) = @_;

   my $user = $context->stash('user') or return;

   if (!$context->posted && $token && $token ne 'reset') {
      if (my $stash = $self->redis->get($token)) {
         $self->redis->remove($token);

         my $options = { context => $context, user => $user };

         $context->stash( form => $self->new_form('TOTP::Secret', $options) );
      }
      else { $self->error($context, UnknownToken, [$token]) }

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
      my $message = 'User [_1] TOTP reset request sent [_2]';
      my $login   = $context->uri_for_action('page/login');

      $context->stash(redirect $login, [$message, "${user}", $job->label]);
   }

   $context->stash( form => $form );
   return;
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
