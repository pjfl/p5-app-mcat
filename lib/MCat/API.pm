package MCat::API;

use MCat::Constants        qw( EXCEPTION_CLASS FALSE NUL TRUE );
use HTTP::Status           qw( HTTP_BAD_REQUEST HTTP_FORBIDDEN
                               HTTP_INTERNAL_SERVER_ERROR HTTP_OK
                               HTTP_UNAUTHORIZED HTTP_UNPROCESSABLE_ENTITY );
use Unexpected::Types      qw( HashRef Int Str );
use Class::Usul::Cmd::Util qw( includes );
use List::Util             qw( first );
use MCat::Util             qw( create_token digest );
use MIME::Base64           qw( decode_base64url encode_base64url );
use Scalar::Util           qw( blessed );
use Type::Utils            qw( class_type );
use Web::Components::Util  qw( load_components );
use Unexpected::Functions  qw( throw );
use Try::Tiny;
use Moo;

with 'MCat::Role::Schema';
with 'MCat::Role::Redis';
with 'MCat::Role::JSONParser';

has 'access_token_lifetime' => is => 'ro', isa => Int, default => 7_200;

has 'config' => is => 'ro', required => TRUE;

has 'entities' =>
   is      => 'lazy',
   isa     => HashRef[class_type('MCat::API::Base')],
   default => sub {
      my $self = shift;
      my @args = (application => $self, schema => $self->schema);

      return load_components 'API', @args;
   };

has 'log' => is => 'ro', required => TRUE;

has 'request_token_lifetime' => is => 'ro', isa => Int, default => 180;

# TODO: API versioning
has 'route_prefix' => is => 'ro', isa => Str, default => 'api/v1';

has 'secret' => is => 'lazy', isa => Str, default => NUL;

sub access_token {
   my ($self, $context) = @_;

   my $token = $context->body_parameters->{request_token};

   return [HTTP_UNAUTHORIZED, { message => 'No request token' }] unless $token;

   my $userid = $self->redis_client->get("api_request-${token}");

   return [HTTP_UNAUTHORIZED, { message => 'No cached token' }] unless $userid;

   $self->redis_client->del("api_request-${token}");

   my $user = $context->find_user({ username => $userid });

   return [HTTP_UNAUTHORIZED, { message => "User ${userid} not found" }]
      unless $user;

   return [HTTP_OK, { access_token => $self->_create_access_token($user) }];
}

sub authorise {
   my ($self, $context) = @_;

   my $options = {
      address  => $context->request->remote_address,
      username => $context->body_parameters->{username},
      password => $context->body_parameters->{password},
   };
   my $result;

   try {
      $context->logout;
      $options->{user} = $context->find_user($options);
      $context->authenticate($options);

      my $token    = create_token;
      my $userid   = $options->{user}->id;
      my $lifetime = $self->request_token_lifetime;
      my $key      = "api_request-${token}";

      $self->redis_client->set_with_ttl($key, $userid, $lifetime);
      $result = [HTTP_OK, { request_token => $token }];
   }
   catch { $result = [HTTP_UNAUTHORIZED, { message => "${_}" }] };

   return $result;
}

sub dispatch {
   my ($self, $context, @args) = @_;

   my $result = $self->_is_authorised($context);

   return $result if $result->[0] > 299;

   my $claim = $result->[1];

   $self->_update_session($context, $claim);

   try {
      my $chain = $context->stash('method_chain');
      my (undef, $moniker, $action) = split m{ / }mx, $chain;
      my $entity = $self->entities->{$moniker};

      $result = $self->_is_allowed($claim, $entity, $action);
      $result = $entity->$action($context, @args) unless $result;
   }
   catch {
      my $rv      = HTTP_INTERNAL_SERVER_ERROR;
      my $message = blessed $_ && $_->can('original') ? $_->original : "${_}";
      my $code    = blessed $_ && $_->can('rv') && $_->rv > 99 ? $_->rv : $rv;

      chomp $message;
      $result = [$code, { message => $message }];
   };

   return $result;
}

# TODO: Add documentation index
sub documentation {
   my ($self, $moniker) = @_;

   return $self->entities->{$moniker};
}

sub refresh {
   my ($self, $context) = @_;

   my $result = $self->_is_authorised($context);

   return $result if $result->[0] > 299;

   my $claim = $result->[1];

   return [HTTP_OK, { access_token => $self->_encode_access_token($claim) }];
}

sub routes {
   my $self   = shift;
   my $prefix = $self->route_prefix;
   my @routes = ();

   for my $moniker (keys %{$self->entities}) {
      my $entity = $self->entities->{$moniker};

      for my $method (@{$entity->method_list}) {
         my $match  = $method->route_match;
         my $route  = $method->method . " + /${prefix}${match} + ?*";
         my $action = $method->action;

         push @routes, $route, "rest/dispatch/${moniker}/${action}";
      }
   }

   return @routes;
}

# Private methods
sub _create_access_token {
   my ($self, $user) = @_;

   my $role = $user->role->name;

   return $self->_encode_access_token({ id => $user->id, role => $role });
}

sub _decode_access_token {
   my ($self, $token) = @_;

   my ($payload, $verify) = split m{ \. }mx, $token;
   my $secret = $self->secret;
   my $calculated = _jwt_hash("${payload}${secret}");

   return {} unless $verify eq $calculated;

   return $self->json_parser->decode(decode_base64url($payload));
}

sub _encode_access_token {
   my ($self, $claim) = @_;

   $claim->{time} = time;

   my $payload = encode_base64url($self->json_parser->encode($claim));
   my $secret  = $self->secret;
   my $verify  = _jwt_hash("${payload}${secret}");

   return "${payload}.${verify}";
}

sub _is_allowed {
   my ($self, $claim, $entity, $action) = @_;

   my $method = first { $_->name eq $action } @{$entity->method_list};

   return [HTTP_UNPROCESSABLE_ENTITY, { message => "Method ${action} unknown" }]
      unless $method;

   if ($method->access->{read}) {
      my $can_read = includes $claim->{role}, [qw(view edit manager admin)];

      return [HTTP_FORBIDDEN, { message => 'No read access' }] unless $can_read;
   }

   if ($method->access->{write}) {
      my $can_write = includes $claim->{role}, [qw(edit manager admin)];

      return [HTTP_FORBIDDEN, { message => 'No write access' }]
         unless $can_write;
   }

   return;
}

sub _is_authorised {
   my ($self, $context) = @_;

   my $header = $context->request->header('Authorization');

   return [HTTP_BAD_REQUEST, { message => 'No authorization header'}]
      unless $header;

   my ($type, $token) = split m{ [ ]+ }mx, $header;

   return [HTTP_BAD_REQUEST, { message => 'No access token' }] unless $token;

   my $claim = $self->_decode_access_token($token);

   return [HTTP_UNAUTHORIZED, { message => 'Token verification failed'}]
      unless $claim->{id};

   my $elapsed = time - $claim->{time};

   return [HTTP_UNAUTHORIZED, { message => 'Token too old' }]
      unless $elapsed < $self->access_token_lifetime;

   return [HTTP_OK, $claim];
}

sub _update_session {
   my ($self, $context, $claim) = @_;

   my $session = $context->session;

   $session->address($context->request->remote_address);
   $session->authenticated(TRUE);
   $session->id($claim->{id});
   $session->role($claim->{role});
   return;
}

# Private functions
sub _jwt_hash {
   return substr digest(shift)->hexdigest, 0, 32;
}

use namespace::autoclean;

1;
