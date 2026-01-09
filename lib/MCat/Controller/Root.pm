package MCat::Controller::Root;

use Web::Components::Util qw( build_routes );
use Web::Simple;

with 'Web::Components::Role';
with 'Web::Components::ReverseMap';

has '+moniker' => default => 'z_root'; # Must sort to last place

sub dispatch_request { build_routes
   'GET      + /api/form/*/field/*/validate + ?*' => 'api/form/field/validate',
   'GET      + /api/messages/collect + ?*'        => 'api/collect_messages',
   'GET      + /api/object/*/fetch + ?*'          => 'api/object/fetch',
   'POST     + /api/table/*/action + ?*'          => 'api/table/action',
   'GET|POST + /api/table/*/preference + ?*'      => 'api/table/preference',

   'GET      + /bug/attachment/* + ?*'      => 'bug/root/attachment',
   'GET|POST + /bug/create + ?*'            => 'bug/root/base/create',
   'GET      + /bug/*/attach + ?*'          => 'bug/root/base/attach',
   'POST     + /bug/*/attach + *file~ + ?*' => 'bug/root/base/attach',
   'POST     + /bug/*/delete + ?*'          => 'bug/root/base/delete',
   'GET|POST + /bug/*/edit + ?*'            => 'bug/root/base/edit',
   'GET|POST + /bug/* + ?*'                 => 'bug/root/base/view',
   'GET      + /bug + ?*'                   => 'bug/root/base/list',

   'GET|POST + /filemanager/copy + ?*'        => 'file/root/base/copy',
   'GET|POST + /filemanager/create + ?*'      => 'file/root/base/create',
   'GET|POST + /filemanager/preview/*.* + ?*' => 'file/root/base/view',
   'GET|POST + /filemanager/properties + ?*'  => 'file/root/base/properties',
   'GET|POST + /filemanager/rename + ?*'      => 'file/root/base/rename',
   'GET      + /filemanager/select + ?*'      => 'file/root/base/select',
   'GET      + /filemanager/upload + ?*'      => 'file/root/base/upload',
   'POST     + /filemanager/upload + *file~'  => 'file/root/base/upload',
   'GET      + /filemanager/*/header'         => 'file/root/base/header',
   'GET      + /filemanager + ?*'             => 'file/root/base/list',

   'GET|POST + /job/status + ?*' => 'job/root/base/status',

   'GET|POST + /user/create + ?*'       => 'user/root/base/create',
   'POST     + /user/*/delete + ?*'     => 'user/root/user/delete',
   'GET|POST + /user/*/edit + ?*'       => 'user/root/user/edit',
   'GET      + /user/*/password/* + ?*' => 'misc/root/user/password_update',
   'GET|POST + /user/*/password + ?*'   => 'misc/root/user/password',
   'GET|POST + /user/*/profile + ?*'    => 'user/root/user/profile',
   'GET|POST + /user/*/totp/reset + ?*' => 'misc/root/user/totp_reset',
   'GET      + /user/*/totp/* + ?*'     => 'misc/root/user/totp',
   'GET      + /user/*/totp + ?*'       => 'user/root/user/totp',
   'GET      + /user/* + ?*'            => 'user/root/user/view',
   'GET      + /user + ?*'              => 'user/root/base/list',

   'GET      + /doc/configuration + ?*' => 'doc/root/base/configuration',
   'GET      + /doc/select + ?*'        => 'doc/root/base/select',
   'GET      + /doc/*.* + ?*'           => 'doc/root/base/view',
   'GET      + /doc + ?*'               => 'doc/root/base/list',

   'POST     + /logfile/*/clear + ?*' => 'logfile/root/clear_cache',
   'GET      + /logfile/*.* + ?*'     => 'logfile/root/base/view',
   'GET      + /logfile + ?*'         => 'logfile/root/base/list',

   'GET      + /changes + ?*'      => 'misc/root/base/changes',
   'GET      + /contact + ?*'      => 'misc/root/base/contact',
   'POST     + /login + ?*'        => 'misc/root/base/login_dispatch',
   'GET      + /login + ?*'        => 'misc/root/base/login',
   'POST     + /logout + ?*'       => 'misc/root/logout',
   'GET      + /register/* + ?*'   => 'misc/root/base/create_user',
   'GET|POST + /register + ?*'     => 'misc/root/base/register',
   'GET      + /unauthorised + ?*' => 'misc/root/base/unauthorised',

   'GET + /footer/** + ?*' => 'misc/footer',

   'GET    + /** + ?*' => 'misc/root/not_found',
   'GET    + ?*'       => 'misc/root/default',
   'HEAD   + ?*'       => 'misc/root/not_found',
   'PUT    + ?*'       => 'misc/root/not_found',
   'POST   + ?*'       => 'misc/root/not_found',
   'DELETE + ?*'       => 'misc/root/not_found',
}

1;
