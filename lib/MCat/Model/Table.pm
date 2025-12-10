package MCat::Model::Table;

use HTML::Forms::Constants qw( EXCEPTION_CLASS );
use MCat::Util             qw( redirect );
use Unexpected::Functions  qw( UnknownTable Unspecified );
use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'table';

sub base {
   my ($self, $context, $tableid) = @_;

   my $nav = $context->stash('nav')->list('table')->item('table/create');

   if ($tableid) {
      my $table = $context->model('Table')->find($tableid);

      return $self->error($context, UnknownTable, [$tableid]) unless $table;

      $context->stash( table => $table );
      $nav->crud('table', $tableid);
   }

   $nav->finalise;
   return;
}

sub create : Nav('Create Table') {
   my ($self, $context) = @_;

   my $options = { context => $context, title => 'Create Table' };
   my $form    = $self->new_form('Table', $options);

   if ($form->process( posted => $context->posted )) {
      my $tableid    = $form->item->id;
      my $table_view = $context->uri_for_action('table/view', [$tableid]);
      my $message    = ['Table [_1] created', $form->item->name];

      $context->stash( redirect $table_view, $message );
   }

   $context->stash( form => $form );
   return;
}

sub delete : Nav('Delete Table') {
   my ($self, $context, $tableid) = @_;

   return unless $self->verify_form_post($context);

   my $table = $context->model('Table')->find($tableid);

   return $self->error($context, UnknownTable, [$tableid]) unless $table;

   my $name = $table->name;

   $table->delete;

   my $table_list = $context->uri_for_action('table/list');

   $context->stash( redirect $table_list, ['Table [_1] deleted', $name] );
   return;
}

sub edit : Nav('Edit Table') {
   my ($self, $context, $tableid) = @_;

   my $form = $self->new_form('Table', {
      context => $context,
      item    => $context->stash('table'),
      title   => 'Edit table'
   });

   if ($form->process( posted => $context->posted )) {
      my $table_view = $context->uri_for_action('table/view', [$tableid]);
      my $message    = ['Table [_1] updated', $form->item->name];

      $context->stash( redirect $table_view, $message );
   }

   $context->stash( form => $form );
   return;
}

sub list : Nav('Tables') {
   my ($self, $context) = @_;

   $context->stash(table => $self->new_table('Table', { context => $context }));
   return;
}

sub view : Nav('View Table') {
   my ($self, $context, $tableid) = @_;

   $context->stash(table => $self->new_table('View::Object', {
      caption => 'Table View',
      context => $context,
      result  => $context->stash('table')
   }));
   return;
}

1;
