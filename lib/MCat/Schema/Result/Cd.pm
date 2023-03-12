package MCat::Schema::Result::Cd;

use strictures;
use parent 'DBIx::Class::Core';

use HTML::Forms::Constants qw( FALSE TRUE );

my $class = __PACKAGE__;

$class->load_components('InflateColumn::DateTime');
$class->table('cd');

$class->add_columns(
   cdid => {
      data_type => 'integer', is_auto_increment => TRUE, is_nullable => FALSE
   },
   artistid => {
      data_type => 'integer', is_foreign_key => TRUE, is_nullable => FALSE
   },
   title => { data_type => 'text', is_nullable => FALSE },
   year => {
      data_type => 'timestamp', is_nullable => TRUE, timezone => 'UTC'
   },
);

$class->set_primary_key('cdid');

$class->add_unique_constraint('cd_title_artistid', ['title', 'artistid']);

$class->belongs_to(
  artist => 'MCat::Schema::Result::Artist',
  { artistid => 'artistid' },
  { is_deferrable => FALSE, on_delete => 'CASCADE', on_update => 'CASCADE' },
);

$class->has_many(
  tracks => 'MCat::Schema::Result::Track',
  { 'foreign.cdid' => 'self.cdid' },
  { cascade_copy => FALSE, cascade_delete => FALSE },
);

1;
