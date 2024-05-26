package MCat::Schema::Result::Import;

use overload '""' => sub { $_[0]->_as_string },
             '+'  => sub { $_[0]->_as_number }, fallback => 1;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE NUL TRUE );
use Class::Usul::Cmd::Util qw( now_dt );
use JSON::MaybeXS          qw( decode_json encode_json );
use DBIx::Class::Moo::ResultClass;

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
   table_id => {
      data_type   => 'integer',
      display     => 'core_table.name',
      is_nullable => FALSE,
      label       => 'Table',
   },
   source => {
      data_type   => 'text',
      is_nullable => FALSE,
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

# Private methods
sub _as_number {
   return $_[0]->id;
}

sub _as_string {
   return $_[0]->name . '-' . $_[0]->id;
}

1;
