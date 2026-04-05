package MCat::Controller::Root;

use Web::Components::Util qw( build_routes );
use Web::Simple;

with 'Web::Components::Role';
with 'Web::Components::ReverseMap';

has '+moniker' => default => 'z_root'; # Must sort to last place

sub dispatch_request { build_routes
   'GET    + /** + ?*' => 'misc/root/not_found',
   'GET    + ?*'       => 'misc/root/default',
   'HEAD   + ?*'       => 'misc/root/not_found',
   'PUT    + ?*'       => 'misc/root/not_found',
   'POST   + ?*'       => 'misc/root/base/login_dispatch',
   'DELETE + ?*'       => 'misc/root/not_found',
}

1;
