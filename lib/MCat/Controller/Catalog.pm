package MCat::Controller::Catalog;

use Web::Simple;

with 'Web::Components::Role';
with 'Web::Components::ReverseMap';

has '+moniker' => default => 'catalog';

sub dispatch_request {
return (
   'GET|POST + /artist/create + ?*' => sub {['artist/root/base/create', @_]},
   'GET|POST + /artist/*/edit + ?*' => sub {['artist/root/base/edit',   @_]},
   'POST + /artist/*/delete + ?*'   => sub {['artist/root/delete',      @_]},
   'GET + /artist/* + ?*'           => sub {['artist/root/base/view',   @_]},
   'GET + /artist + ?*'             => sub {['artist/root/base/list',   @_]},

   'GET|POST + /artist/*/cd/create + ?*' => sub {['cd/root/base/create', @_]},
   'GET|POST + /cd/*/edit + ?*'          => sub {['cd/root/base/edit',   @_]},
   'POST + /cd/*/delete + ?*'            => sub {['cd/root/delete',      @_]},
   'GET + /cd/* + ?*'                    => sub {['cd/root/base/view',   @_]},
   'GET + /artist/*/cd | /cd + ?*'       => sub {['cd/root/base/list',   @_]},

   'GET|POST + /cd/*/track/create + ?*' => sub {['track/root/base/create', @_]},
   'GET|POST + /track/*/edit + ?*'      => sub {['track/root/base/edit',   @_]},
   'POST + /track/*/delete + ?*'        => sub {['track/root/delete',      @_]},
   'GET + /track/* + ?*'                => sub {['track/root/base/view',   @_]},
   'GET + /cd/*/track | /track + ?*'    => sub {['track/root/base/list',   @_]},

   'GET|POST + /tag/create + ?*' => sub {['tag/root/base/create', @_]},
   'GET|POST + /tag/*/edit + ?*' => sub {['tag/root/base/edit',   @_]},
   'POST + /tag/*/delete + ?*'   => sub {['tag/root/delete',      @_]},
   'GET + /tag/* + ?*'           => sub {['tag/root/base/view',   @_]},
   'GET + /tag + ?*'             => sub {['tag/root/base/list',   @_]},
)}

1;
