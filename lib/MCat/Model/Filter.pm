package MCat::Model::Filter;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE NUL TRUE );
use MCat::Util             qw( redirect );
use Unexpected::Functions  qw( UnknownFilter UnknownSelector UnknownTable );
use Moo;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'filter';

sub base {
   my ($self, $context) = @_;

   $context->stash('nav')->list('filter')->item('filter/create')->finalise;

   return;
}

sub filter : Capture(1) {
   my ($self, $context, $filterid) = @_;

   my $filter = $context->model('Filter')->find($filterid);

   return $self->error($context, UnknownFilter, [$filterid]) unless $filter;

   $context->stash(filter => $filter);

   my $nav = $context->stash('nav')->list('filter')->item('filter/create');

   $nav->crud('filter', $filter->id)->finalise;
   return;
}

sub typename : Capture(1) {
   my ($self, $context, $type) = @_;

   $context->stash(type => $type);
   $context->stash('nav')->list('filter')->item('filter/create')->finalise;
   return;
}

sub create : Nav('Create Filter') {
   my ($self, $context) = @_;

   my $options = { context => $context, title => 'Create Filter' };
   my $form    = $self->new_form('Filter', $options);

   if ($form->process( posted => $context->posted )) {
      my $filterid    = $form->item->id;
      my $filter_view = $context->uri_for_action('filter/view', [$filterid]);
      my $message     = ['Filter [_1] created', $form->item->name];

      $context->stash(redirect $filter_view, $message);
   }

   $context->stash(form => $form);
   return;
}

sub delete : Nav('Delete Filter') {
   my ($self, $context) = @_;

   return unless $self->verify_form_post($context);

   my $filter = $context->stash('filter');
   my $name   = $filter->name;

   $filter->delete;

   my $filter_list = $context->uri_for_action('filter/list');

   $context->stash(redirect $filter_list, ['Filter [_1] deleted', $name]);
   return;
}

sub edit : Nav('Edit Filter') {
   my ($self, $context) = @_;

   my $filter  = $context->stash('filter');
   my $options = {
      context => $context, item => $filter, title => 'Edit Filter'
   };
   my $form = $self->new_form('Filter', $options);

   if ($form->process(posted => $context->posted)) {
      my $filter_view = $context->uri_for_action('filter/view', [$filter->id]);
      my $message     = ['Filter [_1] updated', $form->item->name];

      $context->stash(redirect $filter_view, $message);
      return;
   }

   $context->stash(form => $form);
   return;
}

sub list : Nav('Filters') {
   my ($self, $context) = @_;

   $context->stash(table => $self->new_table('Filter', { context => $context}));
   return;
}

sub selector {
   my ($self, $context) = @_;

   my $type    = $context->stash('type');
   my $params  = $context->request->query_parameters;
   my $tableid = $params->{table_id}
      or return $self->error($context, 'Table id not found');
   my $options = { context => $context };
   my $name    = 'Selector';

   if ($type eq 'field') {
      my $table = $context->model('Table')->find($tableid)
         or return $self->error($context, UnknownTable, [$tableid]);

      $options->{result_class} = $table->name;
      $name .= '::' .  ucfirst $type;
   }
   elsif ($type eq 'list') { $options->{table_id} = $tableid }
   else { return $self->error($context, UnknownSelector, [$type]) }

   $options->{data_type} = $params->{data_type} if $params->{data_type};
   $context->stash(table => $self->new_table($name, $options));
   return;
}

sub view : Nav('View Filter') {
   my ($self, $context) = @_;

   my $filter = $context->stash('filter');
   my $query  = $filter->filter_json ? $filter->to_sql : [ NUL, NUL ];

   $context->stash(table => $self->new_table('View::Filter', {
      add_columns => [ 'SQL' => $query->[0] ],
      caption     => 'Filter View',
      context     => $context,
      result      => $filter
   }));
   return;
}

1;
