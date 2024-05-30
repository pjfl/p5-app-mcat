package MCat::Model::Admin;

use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'admin';

sub menu : Auth('admin') Nav('Admin|img/admin.svg') {
   my ($self, $context) = @_;

   my $nav = $context->stash('nav')->list('admin');

   $nav->menu('page')->item('page/configuration');
   $nav->menu('job')->item('job/status');
   $nav->menu('logfile')->item('logfile/list');
   $nav->menu('user')->item('user/list');
   return;
}

1;
