package MCat::Schema::Result::Track;

use strictures;
use parent 'DBIx::Class::Core';

use HTML::Forms::Constants qw( FALSE TRUE );

my $class = __PACKAGE__;

$class->table('track');

$class->add_columns(
   trackid => {
      data_type => 'integer', is_auto_increment => TRUE, is_nullable => FALSE
   },
   cdid => {
      data_type => 'integer', is_foreign_key => TRUE, is_nullable => FALSE
   },
  title => { data_type => 'text', is_nullable => FALSE },
);

$class->set_primary_key('trackid');

$class->add_unique_constraint('track_title_cdid', ['title', 'cdid']);

$class->belongs_to(
  cd => 'MCat::Schema::Result::Cd',
  { cdid => 'cdid' },
  { is_deferrable => 0, on_delete => 'CASCADE', on_update => 'CASCADE' },
);

1;
