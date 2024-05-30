package MCat::Schema::Result::Cd;

use HTML::Forms::Constants qw( FALSE TRUE );
use DBIx::Class::Moo::ResultClass;

my $class  = __PACKAGE__;
my $result = 'MCat::Schema::Result';

$class->load_components('InflateColumn::DateTime');
$class->table('cd');

$class->add_columns(
   cdid => {
      data_type => 'integer', is_auto_increment => TRUE, is_nullable => FALSE,
      label => 'CD ID'
   },
   artistid => {
      data_type => 'integer', is_foreign_key => TRUE, is_nullable => FALSE,
      label => 'Artist', display => 'artist.name'
   },
   title => { data_type => 'text', is_nullable => FALSE, label => 'Title' },
   year => {
      data_type => 'timestamp', is_nullable => TRUE, timezone => 'UTC',
      label => 'Released', cell_traits => ['Date']
   },
   import_log_id {
      data_type => 'integer', is_nullable => TRUE, label => 'Import Log ID'
   }
);

$class->set_primary_key('cdid');

$class->add_unique_constraint('cd_title_artistid', ['title', 'artistid']);

$class->belongs_to(
  artist => "${result}::Artist",
  { artistid => 'artistid' },
  { is_deferrable => FALSE, on_delete => 'CASCADE', on_update => 'CASCADE' },
);

$class->has_many(
  tracks => "${result}::Track",
  { 'foreign.cdid' => 'self.cdid' },
  { cascade_copy => FALSE, cascade_delete => FALSE },
);

$class->has_many(
   'lists' => "${result}::ListCd", { 'foreign.cdid' => 'self.cdid' }
);

$class->might_have(
   'import_log' => "${result}::ImportLog",
   { 'foreign.import_log_id' => 'self.import_log_id' }
);

1;
