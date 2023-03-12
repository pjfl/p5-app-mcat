package MCat::Controller::Root;

use Web::Simple;

with 'Web::Components::Role';

has '+moniker' => default => 'z_root'; # Must sort to last place

sub dispatch_request {
   return (
      'GET | POST + /api/** + ?*'  => sub {['api/response', @_]},

      'GET | POST + /tag/create + ?*' => sub {['tag/create', @_]},
      'GET | POST + /tag/*/edit + ?*' => sub {['tag/edit',   @_]},
      'POST + /tag/*/delete + ?*'     => sub {['tag/delete', @_]},
      'GET + /tag/* + ?*'             => sub {['tag/view',   @_]},
      'GET + /tag + ?*'               => sub {['tag/list',   @_]},

      'GET | POST + /cd/*/track/create + ?*' => sub {['track/create', @_]},
      'GET | POST + /track/*/edit + ?*'      => sub {['track/edit',   @_]},
      'POST + /track/*/delete + ?*'          => sub {['track/delete', @_]},
      'GET + /track/* + ?*'                  => sub {['track/view',   @_]},
      'GET + /cd/*/track | /track + ?*'      => sub {['track/list',   @_]},

      'GET | POST + /artist/*/cd/create + ?*' => sub {['cd/create', @_]},
      'GET | POST + /cd/*/edit + ?*'          => sub {['cd/edit',   @_]},
      'POST + /cd/*/delete + ?*'              => sub {['cd/delete', @_]},
      'GET + /cd/* + ?*'                      => sub {['cd/view',   @_]},
      'GET + /artist/*/cd | /cd + ?*'         => sub {['cd/list',   @_]},

      'GET | POST + /artist/create + ?*' => sub {['artist/create', @_]},
      'GET | POST + /artist/*/edit + ?*' => sub {['artist/edit',   @_]},
      'POST + /artist/*/delete + ?*'     => sub {['artist/delete', @_]},
      'GET + /artist/* + ?*'             => sub {['artist/view',   @_]},
      'GET + /artist + ?*'               => sub {['artist/list',   @_]},

      'GET + /** + ?*' => sub {['page/not_found', @_]},
      'HEAD + ?*'      => sub {['artist/list',    @_]},
      'GET + ?*'       => sub {['artist/list',    @_]},
      'PUT + ?*'       => sub {['page/not_found', @_]},
      'POST + ?*'      => sub {['page/not_found', @_]},
      'DELETE + ?*'    => sub {['page/not_found', @_]},
   );
}

1;
