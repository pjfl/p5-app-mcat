package MCat::Model::Admin;

use MCat::Constants qw( FALSE TRUE );
use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'admin';

sub menu : Auth('admin') Nav('Admin|img/admin.svg') {
   my ($self, $context) = @_;

   my $nav = $context->stash('nav');

   $nav->list('Configuration')->item('doc/configuration');
   $nav->item('doc/config_edit');

   $nav->list('admin');
   $nav->menu('Configuration', TRUE);
   $nav->item('job/status');
   $nav->menu('logfile')->item('logfile/list');
   return;
}

1;
