package MCat::Model::Import;

use HTML::Forms::Constants       qw( EXCEPTION_CLASS NUL );
use MCat::Util                   qw( redirect );
use Web::ComposableRequest::Util qw( bson64id );
use Unexpected::Functions        qw( UnknownImport Unspecified );
use Try::Tiny;
use Moo;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'import';

sub base {
   my ($self, $context) = @_;

   $context->stash('nav')->list('import')->item('import/create')->finalise;

   return;
}

sub importid : Capture(1) {
   my ($self, $context, $importid) = @_;

   my $import = $context->model('Import')->find($importid);

   return $self->error($context, UnknownImport, [$importid]) unless $import;

   $context->stash(import => $import);

   my $nav = $context->stash('nav')->list('import')->item('import/create');

   $nav->crud('import', $import->id)->finalise;

   return;
}

sub create : Nav('Create Import') {
   my ($self, $context) = @_;

   my $options = { context => $context, title => 'Create Import' };
   my $form    = $self->new_form('Import', $options);

   if ($form->process(posted => $context->posted)) {
      my $view    = $context->uri_for_action('import/view', [$form->item->id]);
      my $message = 'Import [_1] created';

      $context->stash(redirect $view, [$message, $form->item->name]);
   }

   $context->stash(form => $form);
   return;
}

sub delete : Nav('Delete Import') {
   my ($self, $context) = @_;

   return unless $self->verify_form_post($context);

   my $import = $context->stash('import');
   my $name   = $import->name;

   $import->delete;

   my $list = $context->uri_for_action('import/list');

   $context->stash(redirect $list, ['Import [_1] deleted', $name]);
   return;
}

sub edit : Nav('Edit Import') {
   my ($self, $context) = @_;

   my $options = { context => $context, item => $context->stash('import') };
   my $form    = $self->new_form('Import', $options);

   if ($form->process(posted => $context->posted)) {
      my $view    = $context->uri_for_action('import/view', [$form->item->id]);
      my $message = 'Import [_1] updated';

      $context->stash(redirect $view, [$message, $form->item->name]);
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

   return unless $job;

   my $view    = $context->uri_for_action('import/view', [$import->id]);
   my $message = 'Job [_1] created. Import guid [_2]';

   $context->stash(redirect $view, [$message, $job->label, $guid]);
   return;
}

sub view : Nav('View Import') {
   my ($self, $context) = @_;

   my $import  = $context->stash('import');
   my $options = { caption => NUL, context => $context, import => $import };

   $context->stash(table => $self->new_table('View::Import', {
      add_columns => [ 'Logs' => $self->new_table('ImportLog', $options) ],
      context     => $context,
      result      => $import,
   }));
   return;
}

# Private methods
sub _import_file {
   my ($self, $context, $id, $guid) = @_;

   my $user_id = $context->session->id;
   my $prefix  = $self->config->prefix;
   my $program = $self->config->bin->catfile("${prefix}-cli");
   my $args    = "-o guid=${guid} -o id=${id} -o user_id=${user_id}";
   my $command = "${program} ${args} import_file";
   my $options = { command => $command, name => 'import_file' };

   return $context->model('Job')->create($options);
}

1;
