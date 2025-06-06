package MCat::Controller::Catalog;

use Web::Components::Util qw( build_routes );
use Web::Simple;

with 'Web::Components::Role';
with 'Web::Components::ReverseMap';

has '+moniker' => default => 'catalog';

sub dispatch_request { build_routes
   'GET|POST + /artist/create + ?*'   => 'artist/root/base/create',
   'GET|POST + /artist/*/edit + ?*'   => 'artist/root/base/edit',
   'POST     + /artist/*/delete + ?*' => 'artist/root/base/delete',
   'GET      + /artist/* + ?*'        => 'artist/root/base/view',
   'GET      + /artist + ?*'          => 'artist/root/base/list',

   'GET|POST + /artist/*/cd/create + ?*' => 'cd/root/base/create',
   'GET|POST + /cd/*/edit + ?*'          => 'cd/root/base/edit',
   'POST     + /cd/*/delete + ?*'        => 'cd/root/base/delete',
   'GET      + /cd/* + ?*'               => 'cd/root/base/view',
   'GET      + /artist/*/cd | /cd + ?*'  => 'cd/root/base/list',

   'GET|POST + /cd/*/track/create + ?*'   => 'track/root/base/create',
   'GET|POST + /track/*/edit + ?*'        => 'track/root/base/edit',
   'POST     + /track/*/delete + ?*'      => 'track/root/base/delete',
   'GET      + /track/* + ?*'             => 'track/root/base/view',
   'GET      + /cd/*/track | /track + ?*' => 'track/root/base/list',

   'GET|POST + /import/create + ?*'   => 'import/root/base/create',
   'GET|POST + /import/*/edit + ?*'   => 'import/root/base/edit',
   'POST     + /import/*/delete + ?*' => 'import/root/base/delete',
   'POST     + /import/*/update + ?*' => 'import/root/base/update',
   'GET      + /import/* + ?*'        => 'import/root/base/view',
   'GET      + /import + ?*'          => 'import/root/base/list',

   'GET      + /importlog/* + ?*'               => 'importlog/root/base/view',
   'GET      + /import/*/log | /importlog + ?*' => 'importlog/root/base/list',

   'GET|POST + /list/create + ?*'   => 'list/root/base/create',
   'GET|POST + /list/*/edit + ?*'   => 'list/root/base/edit',
   'POST     + /list/*/delete + ?*' => 'list/root/base/delete',
   'GET|POST + /list/*/update + ?*' => 'list/root/base/update',
   'GET      + /list/* + ?*'        => 'list/root/base/view',
   'GET      + /list + ?*'          => 'list/root/base/list',

   'GET|POST + /filter/create + ?*'     => 'filter/root/base/create',
   'GET      + /filter/selector/* + ?*' => 'filter/root/base/selector',
   'GET|POST + /filter/*/edit + ?*'     => 'filter/root/base/edit',
   'POST     + /filter/*/delete + ?*'   => 'filter/root/base/delete',
   'GET      + /filter/* + ?*'          => 'filter/root/base/view',
   'GET      + /filter + ?*'            => 'filter/root/base/list',

   'GET|POST + /table/create + ?*'   => 'table/root/base/create',
   'GET|POST + /table/*/edit + ?*'   => 'table/root/base/edit',
   'POST     + /table/*/delete + ?*' => 'table/root/base/delete',
   'GET      + /table/* + ?*'        => 'table/root/base/view',
   'GET      + /table + ?*'          => 'table/root/base/list',

   'GET|POST + /tag/create + ?*'   => 'tag/root/base/create',
   'GET|POST + /tag/*/edit + ?*'   => 'tag/root/base/edit',
   'POST     + /tag/*/delete + ?*' => 'tag/root/base/delete',
   'GET      + /tag/* + ?*'        => 'tag/root/base/view',
   'GET      + /tag + ?*'          => 'tag/root/base/list',
}

1;
