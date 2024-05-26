package MCat::Controller::Catalog;

use Web::Simple;

with 'Web::Components::Role';
with 'Web::Components::ReverseMap';

has '+moniker' => default => 'catalog';

sub dispatch_request {
return (
   'GET|POST + /artist/create + ?*' => sub {['artist/root/base/create', @_]},
   'GET|POST + /artist/*/edit + ?*' => sub {['artist/root/base/edit',   @_]},
   'POST + /artist/*/delete + ?*'   => sub {['artist/root/base/delete', @_]},
   'GET + /artist/* + ?*'           => sub {['artist/root/base/view',   @_]},
   'GET + /artist + ?*'             => sub {['artist/root/base/list',   @_]},

   'GET|POST + /artist/*/cd/create + ?*' => sub {['cd/root/base/create', @_]},
   'GET|POST + /cd/*/edit + ?*'          => sub {['cd/root/base/edit',   @_]},
   'POST + /cd/*/delete + ?*'            => sub {['cd/root/base/delete', @_]},
   'GET + /cd/* + ?*'                    => sub {['cd/root/base/view',   @_]},
   'GET + /artist/*/cd | /cd + ?*'       => sub {['cd/root/base/list',   @_]},

   'GET|POST + /cd/*/track/create + ?*' => sub {['track/root/base/create', @_]},
   'GET|POST + /track/*/edit + ?*'      => sub {['track/root/base/edit',   @_]},
   'POST + /track/*/delete + ?*'        => sub {['track/root/base/delete', @_]},
   'GET + /track/* + ?*'                => sub {['track/root/base/view',   @_]},
   'GET + /cd/*/track | /track + ?*'    => sub {['track/root/base/list',   @_]},

   'GET|POST + /import/create + ?*' => sub {['import/root/base/create',   @_]},
   'GET|POST + /import/*/edit + ?*' => sub {['import/root/base/edit',     @_]},
   'POST + /import/*/delete + ?*'   => sub {['import/root/base/delete',   @_]},
   'GET + /import/* + ?*'           => sub {['import/root/base/view',     @_]},
   'GET + /import + ?*'             => sub {['import/root/base/list',     @_]},

   'GET|POST + /list/create + ?*'   => sub {['list/root/base/create', @_]},
   'GET|POST + /list/*/edit + ?*'   => sub {['list/root/base/edit',   @_]},
   'POST + /list/*/delete + ?*'     => sub {['list/root/base/delete', @_]},
   'GET|POST + /list/*/update + ?*' => sub {['list/root/base/update', @_]},
   'GET + /list/* + ?*'             => sub {['list/root/base/view',   @_]},
   'GET + /list + ?*'               => sub {['list/root/base/list',   @_]},

   'GET|POST + /filter/create + ?*' => sub {['filter/root/base/create',   @_]},
   'GET + /filter/selector/* + ?*'  => sub {['filter/root/base/selector', @_]},
   'GET|POST + /filter/*/edit + ?*' => sub {['filter/root/base/edit',     @_]},
   'POST + /filter/*/delete + ?*'   => sub {['filter/root/base/delete',   @_]},
   'GET + /filter/* + ?*'           => sub {['filter/root/base/view',     @_]},
   'GET + /filter + ?*'             => sub {['filter/root/base/list',     @_]},

   'GET|POST + /table/create + ?*' => sub {['table/root/base/create', @_]},
   'GET|POST + /table/*/edit + ?*' => sub {['table/root/base/edit',   @_]},
   'POST + /table/*/delete + ?*'   => sub {['table/root/base/delete', @_]},
   'GET + /table/* + ?*'           => sub {['table/root/base/view',   @_]},
   'GET + /table + ?*'             => sub {['table/root/base/list',   @_]},

   'GET|POST + /tag/create + ?*' => sub {['tag/root/base/create', @_]},
   'GET|POST + /tag/*/edit + ?*' => sub {['tag/root/base/edit',   @_]},
   'POST + /tag/*/delete + ?*'   => sub {['tag/root/base/delete', @_]},
   'GET + /tag/* + ?*'           => sub {['tag/root/base/view',   @_]},
   'GET + /tag + ?*'             => sub {['tag/root/base/list',   @_]},
)}

1;
