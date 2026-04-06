package MCat::Controller::REST;

use Unexpected::Types     qw( HashRef );
use Web::Components::Util qw( build_routes );
use Type::Utils           qw( class_type );
use Web::Components::API;
use Web::Simple;

with 'Web::Components::Role';
with 'Web::Components::ReverseMap';
with 'MCat::Role::Schema';
with 'MCat::Role::Redis';
with 'MCat::Role::JSONParser';

has '+moniker' => default => 'rest';

has 'api' =>
   is      => 'lazy',
   isa     => class_type('Web::Components::API'),
   default => sub {
      my $self = shift;
      my $args = {
         api_config   => $self->api_config,
         json_parser  => $self->json_parser,
         log          => $self->log,
         redis_client => $self->redis_client,
         schema       => $self->schema,
      };

      return Web::Components::API->new($args);
   };

has 'api_config' => is => 'lazy', isa => HashRef, default => sub { {} };

sub dispatch_request { build_routes
   'POST + /authorise + ?*'    => 'rest/authorise',
   'POST + /access_token + ?*' => 'rest/access_token',
   'POST + /refresh + ?*'      => 'rest/refresh',
   shift->api->routes,
}

1;
