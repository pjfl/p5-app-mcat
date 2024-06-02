package MCat::Model::Import;

use HTML::Forms::Constants       qw( EXCEPTION_CLASS NUL );
use MCat::Util                   qw( redirect );
use Web::ComposableRequest::Util qw( bson64id );
use Unexpected::Functions        qw( UnknownImport Unspecified );
use Try::Tiny;
use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'import';

sub base {
   my ($self, $context, $importid) = @_;

   my $nav = $context->stash('nav')->list('import')->item('import/create');

   if ($importid) {
      my $item = $context->model('Import')->find($importid);

      return $self->error($context, UnknownImport, [$importid]) unless $item;

      $context->stash(import => $item);
      $nav->crud('import', $importid);
   }

   $nav->finalise;
   return;
}

sub create : Nav('Create Import') {
   my ($self, $context) = @_;

   my $options = { context => $context, title => 'Create Import' };
   my $form    = $self->new_form('Import', $options);

   if ($form->process(posted => $context->posted)) {
      my $importid = $form->item->id;
      my $view     = $context->uri_for_action('import/view', [$importid]);
      my $message  = ['Import [_1] created', $form->item->name];

      $context->stash(redirect $view, $message);
   }

   $context->stash(form => $form);
   return;
}

sub delete : Nav('Delete Import') {
   my ($self, $context) = @_;

   return unless $self->verify_form_post($context);

   my $item = $context->stash('import');
   my $name = $item->name;

   $item->delete;

   my $list = $context->uri_for_action('import/list');

   $context->stash(redirect $list, ['Import [_1] deleted', $name]);
   return;
}

sub edit : Nav('Edit Import') {
   my ($self, $context) = @_;

   my $item = $context->stash('import');
   my $form = $self->new_form('Import', {
      context => $context,
      item    => $item,
      title   => 'Edit Import'
   });

   if ($form->process(posted => $context->posted)) {
      my $view    = $context->uri_for_action('import/view', [$item->id]);
      my $message = ['Import [_1] updated', $form->item->name];

      $context->stash(redirect $view, $message);
   }

   $context->stash(form => $form);
   return;
}

sub list : Nav('Imports') {
   my ($self, $context) = @_;

   my $options = { context => $context };

   $context->stash(table => $self->new_table('Import', $options));
   return;
}

sub update {
   my ($self, $context) = @_;

   return unless $self->verify_form_post($context);

   my $import = $context->stash('import');
   my $guid   = bson64id;
   my $job;

   try   { $job = $self->_import_file($context, $import->id, $guid) }
   catch { $self->error($context, $_) };

   my $view    = $context->uri_for_action('import/view', [$import->id]);
   my $message = ['Job [_1] created. Import guid [_2]', $job->label, $guid];

   $context->stash(redirect $view, $message);
   return;
}

sub view : Nav('View Import') {
   my ($self, $context) = @_;

   my $options = { caption => NUL, context => $context };
   my $logs    = $self->new_table('ImportLog', $options);

   $context->stash(table => $self->new_table('Import::View', {
      add_columns => [ 'Logs' => $logs ],
      context     => $context,
      result      => $context->stash('import')
   }));
   return;
}

# Private methods
sub _import_file {
   my ($self, $context, $id, $guid) = @_;

   my $user_id = $context->session->id;
   my $program = $self->config->bin->catfile('mcat-cli');
   my $args    = "-o guid=${guid} -o id=${id} -o user_id=${user_id}";
   my $command = "${program} ${args} import_file";
   my $options = { command => $command, name => 'import_file' };

   return $context->model('Job')->create($options);
}

1;
