package MCat::Model::Admin;

use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'admin';

sub menu : Auth('admin') Nav('Admin|img/admin.svg') {
   my ($self, $context) = @_;

   my $nav = $context->stash('nav');

   $nav->list('configuration')->item('doc/config_edit');

   $nav->list('admin');
   $nav->menu('configuration')->item('doc/configuration');
   $nav->menu('doc')->item('doc/list');
   $nav->menu('job')->item('job/status');
   $nav->menu('logfile')->item('logfile/list');
   return;
}

1;
