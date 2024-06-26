package MCat::Schema::Result::Table;

use HTML::Forms::Constants qw( FALSE TRUE );
use DBIx::Class::Moo::ResultClass;

my $class  = __PACKAGE__;
my $result = 'MCat::Schema::Result';

$class->table('tables');

$class->add_columns(
   id => {
      data_type         => 'integer',
      is_auto_increment => TRUE,
      is_nullable       => FALSE,
      label             => 'Table ID',
   },
   name => {
      data_type   => 'text',
      is_nullable => FALSE,
      label       => 'Table Name',
   },
   relation => { # ListArtist ListCd ListTrack
      data_type   => 'text',
      is_nullable => FALSE,
      label       => 'Relation Name',
   },
   key_name => {
      data_type   => 'text',
      is_nullable => FALSE,
      label       => 'Key Name',
   },
   constraint_name => {
      data_type   => 'text',
      is_nullable => FALSE,
      label       => 'Unique Constraint'
   }
);

$class->set_primary_key('id');

$class->add_unique_constraint('table_name_uniq', ['name']);
$class->add_unique_constraint('table_resultset_uniq', ['relation']);

1;
