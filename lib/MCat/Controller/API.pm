package MCat::Controller::API;

use Web::Components::Util qw( build_routes );
use Web::Simple;

with 'Web::Components::Role';
with 'Web::Components::ReverseMap';

has '+moniker' => default => 'api'; # Must sort to last place

sub dispatch_request { build_routes
   'GET      + /api/form/*/field/*/validate + ?*' => 'api/form/field/validate',
   'POST     + /api/level/*/log + ?*'             => 'api/loglevel/logger',
   'GET      + /api/messages/collect + ?*'        => 'api/collect_messages',
   'GET      + /api/object/*/fetch + ?*'          => 'api/object/fetch',
   'GET      + /api/push/publickey + ?*'          => 'api/push_publickey',
   'POST     + /api/push/register + ?*'           => 'api/push_register',
   'GET      + /service-worker'                   => 'api/push_worker',
   'POST     + /api/table/*/action + ?*'          => 'api/table/action',
   'GET|POST + /api/table/*/preference + ?*'      => 'api/table/preference',
}

1;
