package MCat::Controller::Root;

use Web::Components::Util qw( build_routes );
use Web::Simple;

with 'Web::Components::Role';
with 'Web::Components::ReverseMap';

has '+moniker' => default => 'z_root'; # Must sort to last place

sub dispatch_request { build_routes
   'GET|POST + /api/** + ?*' => 'api/root/dispatch',

   'GET|POST + /user/create + ?*'       => 'user/root/base/create',
   'POST     + /user/*/delete + ?*'     => 'user/root/user/delete',
   'GET|POST + /user/*/edit + ?*'       => 'user/root/user/edit',
   'GET|POST + /user/*/password/* + ?*' => 'page/root/user/password_reset',
   'GET|POST + /user/*/password + ?*'   => 'page/root/user/password',
   'GET|POST + /user/*/profile + ?*'    => 'user/root/user/profile',
   'GET|POST + /user/*/totp/* + ?*'     => 'page/root/user/totp_reset',
   'GET      + /user/*/totp + ?*'       => 'user/root/user/totp',
   'GET      + /user/* + ?*'            => 'user/root/user/view',
   'GET      + /user + ?*'              => 'user/root/base/list',

   'GET|POST + /filemanager/copy + ?*'            => 'file/root/base/copy',
   'GET|POST + /filemanager/create + ?*'          => 'file/root/base/create',
   'GET|POST + /filemanager/preview/*.* + ?*'     => 'file/root/base/view',
   'GET|POST + /filemanager/properties + ?*'      => 'file/root/base/properties',
   'GET|POST + /filemanager/rename + ?*'          => 'file/root/base/rename',
   'GET      + /filemanager/select + ?*'          => 'file/root/base/select',
   'GET      + /filemanager/upload + ?*'          => 'file/root/base/upload',
   'POST     + /filemanager/upload + *file~ + ?*' => 'file/root/base/upload',
   'GET      + /filemanager/*/header'             => 'file/root/base/header',
   'GET      + /filemanager + ?*'                 => 'file/root/base/list',

   'GET|POST + /job/status + ?*' => 'job/root/base/status',

   'GET      + /bug/attachment/* + ?*'      => 'bug/root/attachment',
   'GET|POST + /bug/create + ?*'            => 'bug/root/base/create',
   'GET      + /bug/*/attach + ?*'          => 'bug/root/base/attach',
   'POST     + /bug/*/attach + *file~ + ?*' => 'bug/root/base/attach',
   'POST     + /bug/*/delete + ?*'          => 'bug/root/base/delete',
   'GET|POST + /bug/*/edit + ?*'            => 'bug/root/base/edit',
   'GET|POST + /bug/* + ?*'                 => 'bug/root/base/view',
   'GET      + /bug + ?*'                   => 'bug/root/base/list',

   'POST     + /logfile/*/clear + ?*' => 'logfile/root/clear_cache',
   'GET      + /logfile/*.* + ?*'     => 'logfile/root/base/view',
   'GET      + /logfile + ?*'         => 'logfile/root/base/list',

   'GET      + /doc/configuration + ?*' => 'doc/root/base/configuration',
   'GET      + /doc/select + ?*'        => 'doc/root/base/select',
   'GET      + /doc/*.* + ?*'           => 'doc/root/base/view',
   'GET      + /doc + ?*'               => 'doc/root/base/list',

   'GET      + /changes + ?*'      => 'page/root/base/changes',
   'GET      + /contact + ?*'      => 'page/root/base/contact',
   'GET|POST + /login + ?*'        => 'page/root/base/login',
   'POST     + /logout + ?*'       => 'page/root/logout',
   'GET      + /register/* + ?*'   => 'page/root/base/create_user',
   'GET|POST + /register + ?*'     => 'page/root/base/register',
   'GET      + /unauthorised + ?*' => 'page/root/base/unauthorised',

   'GET + /footer/** + ?*' => 'page/footer',

   'GET    + /** + ?*' => 'page/root/not_found',
   'GET    + ?*'       => 'page/root/default',
   'HEAD   + ?*'       => 'page/root/not_found',
   'PUT    + ?*'       => 'page/root/not_found',
   'POST   + ?*'       => 'page/root/not_found',
   'DELETE + ?*'       => 'page/root/not_found',
}

1;
