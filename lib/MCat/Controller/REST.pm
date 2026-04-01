package MCat::Controller::REST;

use Web::Components::Util qw( build_routes );
use Unexpected::Types     qw( HashRef );
use Type::Utils           qw( class_type );
use MCat::API;
use Web::Simple;

with 'Web::Components::Role';
with 'Web::Components::ReverseMap';

has '+moniker' => default => 'rest';

has 'api' =>
   is      => 'lazy',
   isa     => class_type('MCat::API'),
   default => sub {
      my $self = shift;
      my $args = {
         config      => $self->config,
         log         => $self->log,
         rest_config => $self->rest_config,
      };

      return MCat::API->new($args);
   };

has 'rest_config' => is => 'lazy', isa => HashRef, default => sub { {} };

sub dispatch_request { build_routes
   'POST + /api/access_token + ?*'  => 'rest/access_token',
   'GET  + /api/documentation | /api/documentation/* + ?*'
                                    => 'rest/root/base/documentation',
   'POST + /api/authorise + ?*'     => 'rest/authorise',
   'POST + /api/refresh + ?*'       => 'rest/refresh',
   shift->api->routes,
}

1;
