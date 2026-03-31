package MCat::Controller::REST;

use Web::Components::Util qw( build_routes );
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
         config => $self->config, log => $self->log, secret => $self->secret,
      };

      return MCat::API->new($args);
   };

has 'secret' => is => 'lazy', default => q();

sub dispatch_request { build_routes
   shift->api->routes,
   'POST + /api/access_token + ?*'  => 'rest/access_token',
   'GET  + /api/documentation + ?*' => 'rest/root/documentation',
   'POST + /api/authorise + ?*'     => 'rest/authorise',
   'POST + /api/refresh + ?*'       => 'rest/refresh',
}

1;
