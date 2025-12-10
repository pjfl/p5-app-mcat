package MCat::Schema::Result::Import;

use overload '""' => sub { $_[0]->_as_string },
             '+'  => sub { $_[0]->_as_number }, fallback => 1;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE NUL TRUE );
use Class::Usul::Cmd::Util qw( now_dt );
use JSON::MaybeXS          qw( decode_json encode_json );
use Unexpected::Functions  qw( throw PathNotFound );
use Try::Tiny;
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
      hidden      => TRUE,
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
      label       => 'Imported Total',
   },
   guid => {
      data_type => 'text', is_nullable => TRUE, label => 'Last Log ID'
   },
);

$class->set_primary_key('id');

$class->add_unique_constraint('import_name_uniq', ['name']);

$class->belongs_to('core_table', "${result}::Table", {
   'foreign.id' => 'self.table_id'
});

# Public methods
sub process {
   my ($self, $import_id, $guid, $user_id) = @_;

   my $schema   = $self->result_source->schema;
   my $config   = $schema->config;
   my $selected = $self->meta_to_path($self->source);
   my $file     = $self->meta_directory($config)->child($selected);

   throw PathNotFound, ["${file}"] unless $file->exists;

   my $log_attr   = {
      guid          => $guid,
      import_id     => $import_id,
      owner_user_id => $user_id,
      source        => $selected,
      started       => now_dt
   };
   my $import_log = $schema->resultset('ImportLog')->create($log_attr);
   my $substitute = {
      '%false' => FALSE, '%logid' => $import_log->id, '%true' => TRUE
   };
   my $core_table = $self->core_table;
   my $key_name   = $core_table->key_name;
   my $core_rs    = $schema->resultset($core_table->name);
   my $options    = { key => $core_table->constraint_name };
   my $import_map = $self->_get_import_map($config, $core_rs, $key_name);
   my $inserted   = 0;
   my $updated    = 0;
   my $line_no    = 0;
   my $warnings   = [];

   for my $line ($file->getlines) {
      next if $line_no++ == 0;

      my $record = $self->_get_import_record($import_map, $substitute, $line);

      try {
         my $item = $core_rs->update_or_new($record, $options);

         if ($item->in_storage) { $updated += 1 }
         else {
            $item->insert;
            $inserted += 1;
         }
      }
      catch { push @{$warnings}, $_ };
   }

   my $now   = now_dt;
   my $count = $self->count + $inserted + $updated;

   $log_attr = { finished => $now, inserted => $inserted, updated => $updated };
   $import_log->update($log_attr);
   $self->update({ count => $count, guid => $guid, updated => $now });

   return { count => $count, warnings => $warnings };
}

# Private methods
sub _as_number {
   return $_[0]->id;
}

sub _as_string {
   return $_[0]->name . '-' . $_[0]->id;
}

sub _get_import_map {
   my ($self, $config, $core_rs, $key_name) = @_;

   my $index    = {};
   my $field_no = 0;

   for my $field (@{$self->meta_get_header($config, $self->source)}) {
      $index->{$field->{name}} = $field_no++;
   }

   my $col_info   = $core_rs->result_source->columns_info;
   my $fields     = decode_json($self->field_map) || [];
   my $import_map = {};
   my $col_no     = 0;

   for my $col_name (grep { $_ ne $key_name } sort keys %{$col_info}) {
      my $field = $fields->[$col_no++] or last;
      my $value = $import_map->{$col_name} = $field->{name};

      $import_map->{$col_name} = $index->{$value} if exists $index->{$value};
   }

   return $import_map;
}

sub _get_import_record {
   my ($self, $import_map, $substitute, $line) = @_;

   $self->_csv->parse($line);

   my @fields = $self->_csv->fields;
   my $record = {};

   for my $col_name (keys %{$import_map}) {
      my $index = $import_map->{$col_name};

      next unless defined $index && length $index;

      $record->{$col_name} = ('%' eq substr $index, 0, 1)
         ? $substitute->{$index} : $fields[$index];
   }

   return $record;
}

1;
