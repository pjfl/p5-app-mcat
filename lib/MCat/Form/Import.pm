package MCat::Form::Import;

use utf8; # -*- coding: utf-8; -*-

use HTML::Forms::Constants qw( FALSE META NUL SPC TRUE );
use HTML::Forms::Types     qw( ArrayRef Int Str );
use HTML::Entities         qw( encode_entities );
use Type::Utils            qw( class_type );
use JSON::MaybeXS;
use Text::CSV_XS;
use HTML::Forms::Field::DataStructure;
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Model::DBIC';
with    'HTML::Forms::Role::Defaults';
with    'MCat::Role::FileMeta';

has '+info_message' => default => 'You know what to do';
has '+item_class'   => default => 'Import';

has 'extensions' => is => 'ro', isa => Str, default => 'csv';

has '_icons' =>
   is      => 'lazy',
   isa     => Str,
   default => sub {
      return shift->context->request->uri_for('img/icons.svg')->as_string;
   };

has '_json' =>
   is      => 'lazy',
   isa     => class_type(JSON::MaybeXS::JSON),
   default => sub {
      return JSON::MaybeXS->new( convert_blessed => TRUE, utf8 => FALSE );
   };

has '_max_cols' => is => 'rw', isa => Int;

has '_tables' =>
   is      => 'lazy',
   isa     => ArrayRef,
   default => sub { [ shift->context->model('Table')->all ] };

has_field 'name' => order => 6, required => TRUE;

has_field 'source' => type => 'Selector', display_as => '...', order => 7;

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

   return $self->_json->encode($fields);
}

has_field 'submit' => type => 'Button';

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
         default   => $self->_json->encode($col_info),
         fixed     => TRUE,
         form      => $self,
         label     => ' ', # Magic space filling transparent character U+200b
         name      => $field_name,
         order     => 9 + $count,
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

   my $resources = $self->context->config->wcom_resources;
   my $toggle_js = $resources->{toggle} . ".toggleFields('core_table')";
   my $class     = 'HTML::Forms::Field::Select';
   my $field     = $self->new_field_with_traits($class, {
      element_attr => { javascript => qq{onchange="${toggle_js}"} },
      default      => $table_id - 1,
      form         => $self,
      label        => 'Table',
      name         => 'core_table',
      order        => 8,
      parent       => $self,
      toggle       => $toggle,
      traits       => ['+Toggle'],
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
   my $ds       = $context->config->wcom_resources->{data_structure};
   my $modal    = $context->config->wcom_resources->{modal};
   my $args     = encode_entities($self->_json->encode({
      icons    => $self->_icons,
      onchange => qq{${ds}.reload('field_map', '${header}')},
      target   => 'source',
      title    => 'Select File',
      url      => $selector
   }));

   $self->field('source')->selector("${modal}.createSelector(${args})");
   $self->field('field_map')->icons($self->_icons);
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
