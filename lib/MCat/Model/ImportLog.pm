package MCat::Model::ImportLog;

use HTML::Forms::Constants qw( EXCEPTION_CLASS );
use MCat::Util             qw( redirect );
use Unexpected::Functions  qw( UnknownImport UnknownImportLog Unspecified );
use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'importlog';

sub base {
   my ($self, $context, $id) = @_;

   my $method   = $context->endpoint;
   my $importid = $id if $method eq 'list';
   my $logid    = $id if $method eq 'view';
   my $nav      = $context->stash('nav')->list('importlog');

   if ($importid) {
      my $item = $context->model('Import')->find($importid);

      return $self->error($context, UnknownImport, [$importid]) unless $item;

      $context->stash(import => $item);
   }

   if ($logid) {
      my $item = $context->model('ImportLog')->find($logid);

      return $self->error($context, UnknownImportLog, [$logid]) unless $item;

      $nav->item('importlog/view', [$logid]);
      $context->stash(log => $item);
   }

   $nav->finalise;
   return;
}

sub list : Nav('Import Logs') {
   my ($self, $context) = @_;

   my $options = { caption => 'Import Log List', context => $context };

   $context->stash(table => $self->new_table('ImportLog', $options));
   return;
}

sub view : Nav('View Import Log') {
   my ($self, $context) = @_;

   my $options = { context => $context, result => $context->stash('log') };

   $context->stash(table => $self->new_table('ImportLog::View', $options));
   return;
}

1;
