package MCat::Controller::Catalog;

use Web::Components::Util qw( build_routes );
use Web::Simple;

with 'Web::Components::Role';
with 'Web::Components::ReverseMap';

has '+moniker' => default => 'catalog';

sub dispatch_request { build_routes
   'GET|POST + /artist/create + ?*'   => 'artist/root/base/create',
   'GET|POST + /artist/*/edit + ?*'   => 'artist/root/artist/edit',
   'POST     + /artist/*/delete + ?*' => 'artist/root/artist/delete',
   'GET      + /artist/* + ?*'        => 'artist/root/artist/view',
   'GET      + /artist + ?*'          => 'artist/root/base/list',

   'GET|POST + /artist/*/cd/create + ?*' => 'cd/root/artist/create',
   'GET      + /artist/*/cd + ?*'        => 'cd/root/artist/list',
   'GET|POST + /cd/*/edit + ?*'          => 'cd/root/cd/edit',
   'POST     + /cd/*/delete + ?*'        => 'cd/root/cd/delete',
   'GET      + /cd/* + ?*'               => 'cd/root/cd/view',
   'GET      + /cd + ?*'                 => 'cd/root/base/list',

   'GET|POST + /cd/*/track/create + ?*' => 'track/root/cd/create',
   'GET      + /cd/*/track + ?*'        => 'track/root/cd/list',
   'GET|POST + /track/*/edit + ?*'      => 'track/root/track/edit',
   'POST     + /track/*/delete + ?*'    => 'track/root/track/delete',
   'GET      + /track/* + ?*'           => 'track/root/track/view',
   'GET      + /track + ?*'             => 'track/root/base/list',

   'GET|POST + /import/create + ?*'   => 'import/root/base/create',
   'GET|POST + /import/*/edit + ?*'   => 'import/root/importid/edit',
   'POST     + /import/*/delete + ?*' => 'import/root/importid/delete',
   'POST     + /import/*/update + ?*' => 'import/root/importid/update',
   'GET      + /import/* + ?*'        => 'import/root/importid/view',
   'GET      + /import + ?*'          => 'import/root/base/list',

   'GET      + /import/*/log + ?*' => 'importlog/root/importid/list',
   'GET      + /importlog/* + ?*'  => 'importlog/root/importlog/view',
   'GET      + /importlog + ?*'    => 'importlog/root/base/list',

   'GET|POST + /list/create + ?*'   => 'list/root/base/create',
   'GET|POST + /list/*/edit + ?*'   => 'list/root/listname/edit',
   'POST     + /list/*/delete + ?*' => 'list/root/listname/delete',
   'GET|POST + /list/*/update + ?*' => 'list/root/listname/update',
   'GET      + /list/* + ?*'        => 'list/root/listname/view',
   'GET      + /list + ?*'          => 'list/root/base/list',

   'GET      + /filter/selector/* + ?*' => 'filter/root/typename/selector',
   'GET|POST + /filter/create + ?*'     => 'filter/root/base/create',
   'GET|POST + /filter/*/edit + ?*'     => 'filter/root/filter/edit',
   'POST     + /filter/*/delete + ?*'   => 'filter/root/filter/delete',
   'GET      + /filter/* + ?*'          => 'filter/root/filter/view',
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
