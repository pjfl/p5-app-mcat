package MCat::Controller::Root;

use Web::Simple;

with 'Web::Components::Role';
with 'Web::Components::ReverseMap';

has '+moniker' => default => 'z_root'; # Must sort to last place

sub dispatch_request {
return (
   'GET|POST + /api/** + ?*' => sub {['api/root/dispatch', @_]},

   'GET|POST + /user/create + ?*'     => sub {['user/root/base/create',    @_]},
   'GET + /user/has_property + ?*'    => sub {['page/root/has_property',   @_]},
   'GET|POST + /user/*/edit + ?*'     => sub {['user/root/base/edit',      @_]},
   'POST + /user/*/delete + ?*'       => sub {['user/root/base/delete',    @_]},
   'GET|POST + /user/*/password + ?*' => sub {['page/root/base/password',  @_]},
   'GET|POST + /user/*/profile + ?*'  => sub {['user/root/base/profile',   @_]},
   'GET + /user/*/totp + ?*'          => sub {['user/root/base/totp',      @_]},
   'GET + /user/* + ?*'               => sub {['user/root/base/view',      @_]},
   'GET + /user + ?*'                 => sub {['user/root/base/list',      @_]},

   'POST + /logfile/*/clear + ?*' => sub {['logfile/root/clear_cache', @_]},
   'GET + /logfile/* + ?*'        => sub {['logfile/root/base/view',   @_]},
   'GET + /logfile + ?*'          => sub {['logfile/root/base/list',   @_]},

   'GET + /access_denied + ?*' => sub {['page/root/base/access_denied', @_]},
   'GET|POST + /login + ?*'    => sub {['page/root/base/login',         @_]},
   'POST + /logout + ?*'       => sub {['page/root/logout',             @_]},

   'GET + /** + ?*' => sub {['page/root/default',   @_]},
   'GET + ?*'       => sub {['page/root/default',   @_]},
   'HEAD + ?*'      => sub {['page/root/not_found', @_]},
   'PUT + ?*'       => sub {['page/root/not_found', @_]},
   'POST + ?*'      => sub {['page/root/not_found', @_]},
   'DELETE + ?*'    => sub {['page/root/not_found', @_]},
)}

1;
