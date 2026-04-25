package MCat::Model::System;

use MCat::Constants qw( FALSE TRUE );
use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'system';

sub menu : Auth('view') Nav('System|img/system.svg') {
   my ($self, $context) = @_;

   my $nav = $context->stash('nav');

   $nav->list('Documentation')->item('doc/api')->item('doc/application');
   $nav->item('doc/client')->item('doc/server');

   $nav->list('system');
   $nav->menu('Documentation', TRUE);
   $nav->menu('filemanager')->item('file/list');
   $nav->menu('import')->item('import/list');
   $nav->menu('importlog')->item('importlog/list');
   $nav->menu('list')->item('list/list');
   $nav->menu('filter')->item('filter/list');
   $nav->menu('table')->item('table/list');
   $nav->menu('tag')->item('tag/list');
   $nav->menu('user')->item('user/list');
   return;
}

1;
