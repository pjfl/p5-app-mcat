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

has '_rs_names' =>
   is      => 'lazy',
   isa     => ArrayRef,
   default => sub {
      my $self = shift;

      return [ map { $_->name } $self->context->model('Table')->all ];
   };

has_field 'name' => order => 6, required => TRUE;

has_field 'source' => type => 'Selector', display_as => '...', order => 8;

has_field 'field_map' =>
   type        => 'DataStructure',
   label       => ' ', # Magic space filling transparent character U+200b
   order       => 20,
   reorderable => TRUE,
   structure   => [{
      label    => 'Input Fields',
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
   my $toggle   = {};
   my $count    = 1;
   my $default  = $self->item ? $self->item->table_id : 1;
   my $max_cols = 0;

   for my $name (@{$self->_rs_names}) {
      my $col_info = $self->_get_column_info($name);
      my $ncols = @{$col_info};
      my $field_name = lc "fields_${name}";
      my $wrapper_class = [
         'input-datastructure inline ' . ($count == $default ? NUL : ' hide')
      ];
      my $class = 'HTML::Forms::Field::DataStructure';
      my $field = $self->new_field_with_traits($class, {
         default   => $self->_json->encode($col_info),
         fixed     => TRUE,
         form      => $self,
         label     => 'Field Mapping',
         name      => $field_name,
         order     => 9 + $count,
         parent    => $self,
         structure => [{
            label    => "${name} Columns",
            name     => 'name',
            readonly => TRUE,
            type     => 'text'
         }],
         wrapper_class => $wrapper_class,
      });

      $self->add_field($field);
      $toggle->{$count} = [$field_name];
      $max_cols = $ncols if $ncols > $max_cols;
      $count += 1;
   }

   my $js    = qq{onchange="HForms.Toggle.toggleFields('core_table')"};
   my $class = 'HTML::Forms::Field::Select';
   my $field = $self->new_field_with_traits($class, {
      element_attr => { javascript => $js },
      default      => $default - 1,
      form         => $self,
      label        => 'Table',
      name         => 'core_table',
      order        => 7,
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
   my $params   = { extensions => $self->extensions };
   my $context  = $self->context;
   my $selector = $context->uri_for_action('file/select', [], $params);
   my $header   = $context->uri_for_action('file/header', ['%value']);
   my $args     = encode_entities($self->_json->encode({
      icons    => $self->_icons,
      onchange => qq{
         HForms.DataStructure.manager.reload('field_map', '${header}')
      },
      target   => 'source',
      title    => 'Select File',
      url      => $selector
   }));

   $self->field('source')->selector("HFilters.Modal.createSelector(${args})");
   return;
};

# Private methods
sub _get_column_info {
   my ($self, $rs_name) = @_;

   my $rs     = $self->context->model($rs_name);
   my $info   = $rs->result_source->columns_info;
   my $fields = [];

   for my $attr_name (sort keys %{$info}) {
      push @{$fields}, { name => $attr_name };
   }

   return $fields;
}

use namespace::autoclean -except => META;

1;
