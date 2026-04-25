package MCat::Model::Table;

use HTML::Forms::Constants qw( EXCEPTION_CLASS NUL );
use MCat::Util             qw( redirect );
use Unexpected::Functions  qw( UnknownTable Unspecified );
use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'table';

sub base {
   my ($self, $context) = @_;

   $context->stash('nav')->list('table')->item('table/create')->finalise;

   return;
}

sub tableid : Capture(1) {
   my ($self, $context, $tableid) = @_;

   my $table = $context->model('Table')->find($tableid);

   return $self->error($context, UnknownTable, [$tableid]) unless $table;

   $context->stash(core_table => $table);

   my $nav = $context->stash('nav')->list('table')->item('table/create');

   $nav->crud('table', $table->id)->finalise;

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
   my ($self, $context) = @_;

   return unless $self->verify_form_post($context);

   my $table = $context->stash('core_table');
   my $name  = $table->name;

   $table->delete;

   my $table_list = $context->uri_for_action('table/list');

   $context->stash( redirect $table_list, ['Table [_1] deleted', $name] );
   return;
}

sub edit : Nav('Edit Table') {
   my ($self, $context) = @_;

   my $table = $context->stash('core_table');
   my $form  = $self->new_form('Table', {
      context => $context,
      item    => $table,
      title   => 'Edit table'
   });

   if ($form->process( posted => $context->posted )) {
      my $table_view = $context->uri_for_action('table/view', [$table->id]);
      my $message    = 'Table [_1] updated';

      $context->stash(redirect $table_view, [$message, $table->name]);
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
   my ($self, $context) = @_;

   my $table   = $context->stash('core_table');
   my $buttons = [{
      action    => $context->uri_for_action('table/list'),
      classes   => 'left',
      method    => 'get',
      selection => 'disable_on_select',
      value     => 'Tables',
   },{
      action    => $context->uri_for_action('table/edit', [$table->id]),
      method    => 'get',
      selection => 'disable_on_select',
      value     => 'Edit',
   }];
   my $options = { caption => NUL, context => $context, table => $table };
   my $lists   = $self->new_table('List', $options);

   $context->stash(table => $self->new_table('View::Object', {
      add_columns  => [ 'Lists' => $lists ],
      caption      => 'View Table',
      context      => $context,
      form_buttons => $buttons,
      result       => $table,
   }));
   return;
}

1;
