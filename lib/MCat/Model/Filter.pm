package MCat::Model::Filter;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE NUL TRUE );
use HTML::Entities         qw( encode_entities );
use Type::Utils            qw( class_type );
use MCat::Util             qw( formpost redirect );
use Unexpected::Functions  qw( UnknownFilter UnknownTable Unspecified );
use JSON::MaybeXS          qw( encode_json );
use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'filter';

sub base {
   my ($self, $context, $filterid) = @_;

   my $nav = $context->stash('nav');

   if ($filterid && $filterid =~ m{ \A \d+ \z }mx) {
      my $filter = $context->model('Filter')->find($filterid);

      return $self->error($context, UnknownFilter, [$filterid]) unless $filter;

      $context->stash( filter => $filter );
      $nav->list('filter_editor')->item('filter/editor', [$filterid]);
      $nav->list('filter')->item('filter/create');
      $nav->item(formpost, 'filter/delete', [$filterid]);
      $nav->item('filter/edit', [$filterid]);
      $nav->menu('filter_editor')->item('filter/view', [$filterid]);
   }
   else {
      $nav->list('filter')->item('filter/create');
   }

   if ($context->action =~ m{ /editor \z }mx) {
      $context->stash('nav')->container_layout(NUL);
   }

   $nav->finalise;
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

      $context->stash( redirect $filter_view, $message );
   }

   $context->stash( form => $form );
   return;
}

sub delete : Nav('Delete Filter') {
   my ($self, $context, $filterid) = @_;

   return unless $self->verify_form_post($context);

   my $filter = $context->model('Filter')->find($filterid);

   return $self->error($context, UnknownFilter, [$filterid]) unless $filter;

   my $name = $filter->name;

   $filter->delete;

   my $filter_list = $context->uri_for_action('filter/list');

   $context->stash( redirect $filter_list, ['Filter [_1] deleted', $name] );
   return;
}

sub edit : Nav('Edit Filter') {
   my ($self, $context, $filterid) = @_;

   my $form = $self->new_form('Filter', {
      context => $context,
      item    => $context->stash('filter'),
      title   => 'Edit Filter'
   });

   if ($form->process( posted => $context->posted )) {
      my $filter_view = $context->uri_for_action('filter/view', [$filterid]);
      my $message     = ['Filter [_1] updated', $form->item->name];

      $context->stash( redirect $filter_view, $message );
   }

   $context->stash( form => $form );
   return;
}

sub editor : Nav('Filter Editor') {
   my ($self, $context) = @_;

   my $filter  = $context->stash('filter');
   my $options = { context => $context, item => $filter };
   my $form    = $self->new_form('Filter::Editor', $options);

   if ($form->process( posted => $context->posted )) {
      my $filter_view = $context->uri_for_action('filter/view', [$filter->id]);
      my $message     = ['Filter [_1] updated', $form->item->name];

      $context->stash( redirect $filter_view, $message );
      return;
   }

   $context->stash( form => $form );

   my $config = encode_entities encode_json {
      'api-uri'      => 'api/object/*/*',
      'request-base' => $context->request->uri_for(NUL)->as_string,
      'selector-uri' => 'filter/selector/*',
      'table-id'     => $filter->table_id
   };

   $context->stash( filter_config => $config );
   return;
}

sub list : Nav('Filters') {
   my ($self, $context) = @_;

   $context->stash(table => $self->new_table('Filter', { context => $context}));
   return;
}

sub selector {
   my ($self, $context, $type) = @_;

   my $name    = 'Selector::' . ucfirst $type;
   my $params  = $context->request->query_parameters;
   my $tableid = $params->{table_id}
      or return $self->error($context, 'Table id not found');
   my $options;

   if ($type eq 'field') {
      my $table = $context->model('Table')->find($tableid)
         or return $self->error($context, UnknownTable, [$tableid]);

      $options = { context => $context, result_class => $table->name };

      $options->{data_type} = $params->{data_type} if $params->{data_type};
   }
   elsif ($type eq 'list') {
      $options = { context => $context, table_id => $tableid };
   }

   $context->stash(table => $self->new_table($name, $options)) if $options;
   return;
}

sub view : Nav('View Filter') {
   my ($self, $context, $filterid) = @_;

   my $filter = $context->stash('filter');
   my $query  = $filter->to_sql;

   $context->stash(table => $self->new_table('Filter::View', {
      add_columns => [ 'SQL' => $query->[0], 'Bind Values' => $query->[1] ],
      caption     => 'Filter View',
      context     => $context,
      result      => $filter
   }));
   return;
}

1;
