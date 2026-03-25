package MCat::Controller::REST;

use Web::Components::Util qw( build_routes );
use Type::Utils           qw( class_type );
use MCat::API;
use Web::Simple;

with 'Web::Components::Role';

has '+moniker' => default => 'rest';

has 'api' =>
   is      => 'lazy',
   isa     => class_type('MCat::API'),
   default => sub {
      my $self = shift;

      return MCat::API->new(config => $self->config, log => $self->log);
   };

sub dispatch_request {
   build_routes shift->api->routes,
   'POST + /api/access_token + ?*' => 'rest/access_token',
   'POST + /api/authorise + ?*'    => 'rest/authorise',
}

1;
