package MCat::Schema::Result::Import;

use overload '""' => sub { $_[0]->_as_string },
             '+'  => sub { $_[0]->_as_number }, fallback => 1;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE NUL TRUE );
use Class::Usul::Cmd::Util qw( now_dt );
use JSON::MaybeXS          qw( decode_json encode_json );
use Unexpected::Functions  qw( throw PathNotFound );
use DBIx::Class::Moo::ResultClass;

with 'MCat::Role::FileMeta';

my $class  = __PACKAGE__;
my $result = 'MCat::Schema::Result';

$class->load_components('InflateColumn::DateTime');
$class->table('import');

$class->add_columns(
   id => {
      data_type         => 'integer',
      is_nullable       => FALSE,
      is_auto_increment => TRUE,
      label             => 'Import ID',
   },
   name => {
      data_type   => 'text',
      is_nullable => FALSE,
      label       => 'Import Name',
   },
   source => {
      data_type   => 'text',
      is_nullable => FALSE,
   },
   table_id => {
      data_type   => 'integer',
      display     => 'core_table.name',
      is_nullable => FALSE,
      label       => 'Table',
   },
   field_map => {
      data_type   => 'text',
      is_nullable => TRUE,
      label       => 'Field Mapping',
   },
   updated => {
      cell_traits => ['DateTime'],
      data_type   => 'timestamp',
      is_nullable => TRUE,
      timezone    => 'UTC',
   },
   count => {
      data_type   => 'integer',
      is_nullable => TRUE,
   },
);

$class->set_primary_key('id');

$class->add_unique_constraint('import_name_uniq', ['name']);

$class->belongs_to('core_table', "${result}::Table", {
   'foreign.id' => 'self.table_id'
});

# Public methods
sub process {
   my $self     = shift;
   my $schema   = $self->result_source->schema;
   my $selected = $self->meta_to_path($self->source);
   my $file     = $self->meta_directory($schema->config)->child($selected);

   throw PathNotFound, ["${file}"] unless $file->exists;

   my $import_map = $self->_get_import_map($schema);
   # TODO: Add ImportLog result class
   my $log_id     = 99;
   my $substitute = { '%false' => FALSE, '%id' => $log_id, '%true' => TRUE };
   my $count      = 0;
   my $line_no    = 0;

   for my $line ($file->getlines) {
      next if $line_no++ == 0;

      $self->_csv->parse($line);

      my @fields = $self->_csv->fields;
      my $record = {};

      for my $col_name (keys %{$import_map}) {
         my $index = $import_map->{$col_name};

         next unless defined $index && length $index;

         $record->{$col_name} = ('%' eq substr $index, 0, 1)
            ? $substitute->{$index} : $fields[$index];
      }

      # TODO: Add create or update
      $count++;
   }

   return $count;
}

# Private methods
sub _as_number {
   return $_[0]->id;
}

sub _as_string {
   return $_[0]->name . '-' . $_[0]->id;
}

sub _get_import_map {
   my ($self, $schema) = @_;

   my $index    = {};
   my $field_no = 0;

   for my $field (@{$self->meta_get_header($schema->config, $self->source)}) {
      $index->{$field->{name}} = $field_no++;
   }

   my $rs_name    = $self->core_table->name;
   my $col_info   = $schema->resultset($rs_name)->result_source->columns_info;
   my $fields     = decode_json($self->field_map) || [];
   my $import_map = {};
   my $col_no     = 0;

   for my $col_name (sort keys %{$col_info}) {
      my $value = $import_map->{$col_name} = $fields->[$col_no++]->{name};

      $import_map->{$col_name} = $index->{$value} if exists $index->{$value};
   }

   return $import_map;
}

1;
