package MCat::Controller::Root;

use Web::Simple;

with 'Web::Components::Role';
with 'Web::Components::ReverseMap';

has '+moniker' => default => 'z_root'; # Must sort to last place

sub dispatch_request {
return (
   'GET|POST + /api/** + ?*' => sub {['api/dispatch', @_]},

   'GET|POST + /tag/create + ?*' => sub {['tag/root/base/create', @_]},
   'GET|POST + /tag/*/edit + ?*' => sub {['tag/root/base/edit',   @_]},
   'POST + /tag/*/delete + ?*'   => sub {['tag/delete',           @_]},
   'GET + /tag/* + ?*'           => sub {['tag/root/base/view',   @_]},
   'GET + /tag + ?*'             => sub {['tag/root/base/list',   @_]},

   'GET|POST + /cd/*/track/create + ?*' => sub {['track/root/base/create', @_]},
   'GET|POST + /track/*/edit + ?*'      => sub {['track/root/base/edit',   @_]},
   'POST + /track/*/delete + ?*'        => sub {['track/delete',           @_]},
   'GET + /track/* + ?*'                => sub {['track/root/base/view',   @_]},
   'GET + /cd/*/track | /track + ?*'    => sub {['track/root/base/list',   @_]},

   'GET|POST + /artist/*/cd/create + ?*' => sub {['cd/root/base/create', @_]},
   'GET|POST + /cd/*/edit + ?*'          => sub {['cd/root/base/edit',   @_]},
   'POST + /cd/*/delete + ?*'            => sub {['cd/delete',           @_]},
   'GET + /cd/* + ?*'                    => sub {['cd/root/base/view',   @_]},
   'GET + /artist/*/cd | /cd + ?*'       => sub {['cd/root/base/list',   @_]},

   'GET|POST + /artist/create + ?*' => sub {['artist/root/base/create', @_]},
   'GET|POST + /artist/*/edit + ?*' => sub {['artist/root/base/edit',   @_]},
   'POST + /artist/*/delete + ?*'   => sub {['artist/delete',           @_]},
   'GET + /artist/* + ?*'           => sub {['artist/root/base/view',   @_]},
   'GET + /artist + ?*'             => sub {['artist/root/base/list',   @_]},

   'GET + /logfile/* + ?*' => sub {['logfile/root/base/view', @_]},
   'GET + /logfile + ?*'   => sub {['logfile/root/base/list', @_]},

   'GET + /** + ?*' => sub {['page/root/not_found', @_]},
   'HEAD + ?*'      => sub {['page/root/not_found', @_]},
   'GET + ?*'       => sub {['page/root/not_found', @_]},
   'PUT + ?*'       => sub {['page/root/not_found', @_]},
   'POST + ?*'      => sub {['page/root/not_found', @_]},
   'DELETE + ?*'    => sub {['page/root/not_found', @_]},
)}

1;
