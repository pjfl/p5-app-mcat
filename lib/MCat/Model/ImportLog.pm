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
   my ($self, $context) = @_;

   $context->stash('nav')->list('importlog')->finalise;

   return;
}

sub importid : Capture(1) {
   my ($self, $context, $importid) = @_;

   my $item = $context->model('Import')->find($importid);

   return $self->error($context, UnknownImport, [$importid]) unless $item;

   $context->stash(import => $item);

   my $nav = $context->stash('nav')->list('importlog')->finalise;

   return;
}

sub importlog : Capture(1) {
   my ($self, $context, $logid) = @_;

   my $item = $context->model('ImportLog')->find($logid);

   return $self->error($context, UnknownImportLog, [$logid]) unless $item;

   $context->stash(log => $item);

   my $nav = $context->stash('nav')->list('importlog');

   $nav->item('importlog/view', [$logid])->finalise;

   return;
}

sub list : Nav('Import Logs') {
   my ($self, $context) = @_;

   my $options = { caption => 'Import Log List', context => $context };
   my $import  = $context->stash('import');

   $options->{import} = $import if $import;

   $context->stash(table => $self->new_table('ImportLog', $options));
   return;
}

sub view : Nav('View Import Log') {
   my ($self, $context) = @_;

   my $options = { context => $context, result => $context->stash('log') };

   $context->stash(table => $self->new_table('View::ImportLog', $options));
   return;
}

1;
