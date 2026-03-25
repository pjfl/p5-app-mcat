package MCat::API;

use MCat::Constants       qw( EXCEPTION_CLASS FALSE TRUE );
use HTTP::Status          qw( HTTP_INTERNAL_SERVER_ERROR HTTP_NOT_FOUND HTTP_OK
                              HTTP_UNAUTHORIZED );
use Unexpected::Types     qw( HashRef );
use MCat::Util            qw( create_token );
use Type::Utils           qw( class_type );
use Web::Components::Util qw( load_components );
use Unexpected::Functions qw( throw );
use Try::Tiny;
use Moo;

with 'MCat::Role::Schema';
with 'MCat::Role::Redis';

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

sub access_token {
   my ($self, $context) = @_;

   my $token = $context->body_parameters->{request_token};

   return [HTTP_NOT_FOUND, { message => 'No request token' } ] unless $token;

   my $user_id = $self->redis_client->get("api_request-${token}");

   return [HTTP_NOT_FOUND, { message => 'Request token not found' }]
      unless $user_id;

   $self->redis_client->del("api_request-${token}");
   $token = create_token;
   $self->redis_client->set_with_ttl("api_access-${token}", $user_id, 7200);

   return [HTTP_OK, { access_token => $token }];
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

      my $token   = create_token;
      my $user_id = $options->{user}->id;

      $self->redis_client->set_with_ttl("api_request-${token}", $user_id, 180);
      $result = [HTTP_OK, { request_token => $token }];
   }
   catch { $result = [HTTP_UNAUTHORIZED, { message => "${_}" }] };

   return $result;
}

sub dispatch {
   my ($self, $context, @args) = @_;

   my $header = $context->request->header('Authorization')
      or return [HTTP_NOT_FOUND, { message => 'Authorization header'}];

   my ($type, $token) = split m{ [ ]+ }mx, $header;

   return [HTTP_NOT_FOUND, { message => 'Access token' }] unless $token;

   return [HTTP_UNAUTHORIZED, { message => 'Permission denied' }]
      unless $self->redis_client->get("api_access-${token}");

   my $result;

   try {
      my $chain = $context->stash('method_chain');
      my (undef, $moniker, $action) = split m{ / }mx, $chain;
      my $entity = $self->entities->{$moniker};

      $result = $entity->$action($context, @args);
   }
   catch { $result = [HTTP_INTERNAL_SERVER_ERROR, { message => "${_}" }] };

   return $result;
}

sub routes {
   my $self   = shift;
   my @routes = ();

   for my $moniker (keys %{$self->entities}) {
      my $entity = $self->entities->{$moniker};

      for my $method (@{$entity->method_list}) {
         my $route = ($method->{method} // 'GET')
            . ' + /api/v1' . $method->{route} . ' + ?*';
         my $action = $method->{action};

         push @routes, $route, "rest/dispatch/${moniker}/${action}";
      }
   }

   return @routes;
}

use namespace::autoclean;

1;
