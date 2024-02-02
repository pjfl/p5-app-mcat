package MCat::Controller::Root;

use Web::Simple;

with 'Web::Components::Role';
with 'Web::Components::ReverseMap';

has '+moniker' => default => 'z_root'; # Must sort to last place

sub dispatch_request {
return (
   'GET|POST + /api/** + ?*' => sub {['api/root/dispatch', @_]},

   'GET|POST + /user/create + ?*'     => sub {['user/root/base/create',    @_]},
   'GET + /user/property + ?*'        => sub {['page/root/object_property',@_]},
   'POST + /user/*/delete + ?*'       => sub {['user/root/base/delete',    @_]},
   'GET|POST + /user/*/edit + ?*'     => sub {['user/root/base/edit',      @_]},
   'GET|POST + /user/*/password/* + ?*'
                                  => sub {['page/root/base/password_reset',@_]},
   'GET|POST + /user/*/password + ?*' => sub {['page/root/base/password',  @_]},
   'GET|POST + /user/*/profile + ?*'  => sub {['user/root/base/profile',   @_]},
   'GET|POST + /user/*/totp/* + ?*'   => sub {['page/root/base/totp_reset',@_]},
   'GET + /user/*/totp + ?*'          => sub {['user/root/base/totp',      @_]},
   'GET + /user/* + ?*'               => sub {['user/root/base/view',      @_]},
   'GET + /user + ?*'                 => sub {['user/root/base/list',      @_]},

   'GET|POST + /job/status + ?*' => sub {['job/root/base/status', @_]},

   'POST + /logfile/*/clear + ?*' => sub {['logfile/root/clear_cache', @_]},
   'GET + /logfile/* + ?*'        => sub {['logfile/root/base/view',   @_]},
   'GET + /logfile + ?*'          => sub {['logfile/root/base/list',   @_]},

   'GET + /access_denied + ?*'   => sub {['page/root/base/access_denied', @_]},
   'GET + /changes + ?*'         => sub {['page/root/base/changes',       @_]},
   'GET + /configuration + ?*'   => sub {['page/root/base/configuration', @_]},
   'GET|POST + /login + ?*'      => sub {['page/root/base/login',         @_]},
   'POST + /logout + ?*'         => sub {['page/root/logout',             @_]},
   'GET|POST + /register/* | /register + ?*'
                                 => sub {['page/root/base/register',      @_]},

   'GET + /** + ?*' => sub {['page/root/not_found', @_]},
   'GET + ?*'       => sub {['page/root/default',   @_]},
   'HEAD + ?*'      => sub {['page/root/not_found', @_]},
   'PUT + ?*'       => sub {['page/root/not_found', @_]},
   'POST + ?*'      => sub {['page/root/not_found', @_]},
   'DELETE + ?*'    => sub {['page/root/not_found', @_]},
)}

1;
