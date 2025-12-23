package MCat::Form::Import;

use utf8; # -*- coding: utf-8; -*-

use HTML::Forms::Constants qw( FALSE META NUL SPC TRUE );
use HTML::Forms::Types     qw( ArrayRef Int Str );
use HTML::Entities         qw( encode_entities );
use HTML::Forms::Field::DataStructure;
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Model::DBIC';
with    'HTML::Forms::Role::Defaults';
with    'MCat::Role::JSONParser';
with    'MCat::Role::FileMeta';

has '+form_wrapper_class' => default => sub { ['narrow'] };
has '+info_message'       => default => 'You know what to do';
has '+item_class'         => default => 'Import';

has 'extensions' => is => 'ro', isa => Str, default => 'csv';

has '_icons' =>
   is      => 'lazy',
   isa     => Str,
   default => sub { shift->context->icons_uri->as_string };

has '_max_cols' => is => 'rw', isa => Int;

has '_tables' =>
   is      => 'lazy',
   isa     => ArrayRef,
   default => sub { [ shift->context->model('Table')->all ] };

has_field 'name' => order => 6, required => TRUE;

has_field 'source' =>
   type       => 'Selector',
   title      => 'Select File',
   display_as => '...',
   order      => 7;

has_field 'field_map' =>
   type        => 'DataStructure',
   label       => 'Field Mapping',
   order       => 9,
   reorderable => TRUE,
   structure   => [{
      label    => 'Source Fields',
      name     => 'name',
      type     => 'text',
   }],
   wrapper_class => ['input-datastructure inline'];

sub default_field_map {
   my $self   = shift;
   my $fields = [];

   for my $col_no (1 .. $self->_max_cols) {
      push @{$fields}, { name => "Col${col_no}" };
   }

   return $self->json_parser->encode($fields);
}

has_field '_g1' => type => 'Group';

has_field 'view' =>
   type          => 'Link',
   field_group   => '_g1',
   label         => 'View',
   element_class => [qw(form-button pageload)],
   wrapper_class => [qw(input-button left)];

has_field 'submit' => type => 'Button', field_group => '_g1';

after 'before_build_fields' => sub {
   my $self     = shift;
   my $count    = 1;
   my $max_cols = 0;
   my $table_id = $self->item ? $self->item->table_id : 1;
   my $toggle   = {};

   for my $table (@{$self->_tables}) {
      my $col_info      = $self->_get_column_info($table);
      my $ncols         = @{$col_info};
      my $display_class = ($count == $table_id ? NUL : 'hide');
      my $table_name    = $table->name;
      my $field_name    = lc "fields_${table_name}";
      my $field_class   = 'HTML::Forms::Field::DataStructure';
      my $field         = $self->new_field_with_traits($field_class, {
         default   => $self->json_parser->encode($col_info),
         fixed     => TRUE,
         form      => $self,
         label     => ' ', # Magic space filling transparent character U+200b
         name      => $field_name,
         order     => 10 + $count,
         parent    => $self,
         structure => [{
            label    => "${table_name} Columns",
            name     => 'name',
            readonly => TRUE,
            type     => 'text'
         }],
         wrapper_class => ["input-datastructure inline ${display_class}"],
      });

      $self->add_field($field);
      $toggle->{$count} = [$field_name];
      $max_cols = $ncols if $ncols > $max_cols;
      $count += 1;
   }

   my $class     = 'HTML::Forms::Field::Select';
   my $field     = $self->new_field_with_traits($class, {
      default          => $table_id - 1,
      form             => $self,
      label            => 'Table',
      name             => 'core_table',
      order            => 8,
      parent           => $self,
      toggle           => $toggle,
      toggle_animation => FALSE,
      traits           => ['+Toggle'],
   });
   my $accessor = $field->parent->full_accessor if $field->parent;

   $field->options($self->lookup_options($field, $accessor));
   $self->add_field($field);
   $self->_max_cols($max_cols);
   return;
};

after 'after_build_fields' => sub {
   my $self     = shift;
   my $context  = $self->context;
   my $params   = { extensions => $self->extensions };
   my $selector = $context->uri_for_action('file/select', [], $params);
   my $header   = $context->uri_for_action('file/header', ['%value']);
   my $ds       = $context->config->wcom_resources->{datastructure};
   my $modal    = $context->config->wcom_resources->{modal};
   my $reload   = $self->json_parser->encode({
      target => 'field_map',
      url    => $header,
   });
   my $args     = $self->json_parser->encode({
      icons    => $self->_icons,
      onchange => qq{${ds}.reload(${reload})},
      target   => 'source',
      title    => 'Select File',
      url      => $selector,
   });

   $self->field('source')->selector("${modal}.createSelector(${args})");
   $self->field('field_map')->icons($self->_icons);

   if ($self->item) {
      my $view = $context->uri_for_action('import/view', [$self->item->id]);

      $self->field('view')->href($view->as_string);
      $self->field('submit')->add_wrapper_class('right');
   }
   else {
      $self->field('view')->inactive(TRUE);
      $self->field('_g1')->add_wrapper_class('right');
   }

   return;
};

# Private methods
sub _get_column_info {
   my ($self, $table) = @_;

   my $rs       = $self->context->model($table->name);
   my $col_info = $rs->result_source->columns_info;
   my $fields   = [];

   for my $col_name (grep { $_ ne $table->key_name } sort keys %{$col_info}) {
      push @{$fields}, { name => $col_name };
   }

   return $fields;
}

use namespace::autoclean -except => META;

1;
