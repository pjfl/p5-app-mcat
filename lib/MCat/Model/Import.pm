package MCat::Model::Import;

use HTML::Forms::Constants qw( EXCEPTION_CLASS );
use MCat::Util             qw( redirect );
use Unexpected::Functions  qw( UnknownImport Unspecified );
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
      my $importid    = $form->item->id;
      my $import_view = $context->uri_for_action('import/view', [$importid]);
      my $message     = ['Import [_1] created', $form->item->name];

      $context->stash(redirect $import_view, $message);
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

   my $import_list = $context->uri_for_action('import/list');

   $context->stash(redirect $import_list, ['Import [_1] deleted', $name]);
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
      my $import_view = $context->uri_for_action('import/view', [$item->id]);
      my $message     = ['Import [_1] updated', $form->item->name];

      $context->stash(redirect $import_view, $message);
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

sub view : Nav('View Import') {
   my ($self, $context) = @_;

   my $options = { context => $context, result  => $context->stash('import') };

   $context->stash(table => $self->new_table('Import::View', $options));
   return;
}

1;
