package MCat::Model::Manager;

use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'manager';

sub menu : Auth('manager') Nav('Manager|img/manager.svg') {
   my ($self, $context) = @_;

   my $nav = $context->stash('nav')->list('manager');

   $nav->menu('filemanager')->item('file/list');
   $nav->menu('filter')->item('filter/list');
   $nav->menu('import')->item('import/list');
   $nav->menu('importlog')->item('importlog/list');
   $nav->menu('list')->item('list/list');
   $nav->menu('table')->item('table/list');
   $nav->menu('tag')->item('tag/list');
   $nav->menu('user')->item('user/list');
   return;
}

1;
