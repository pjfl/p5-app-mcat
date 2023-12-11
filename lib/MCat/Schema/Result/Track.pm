package MCat::Schema::Result::Track;

use HTML::Forms::Constants qw( FALSE TRUE );
use DBIx::Class::Moo::ResultClass;

my $class  = __PACKAGE__;
my $result = 'MCat::Schema::Result';

$class->table('track');

$class->add_columns(
   trackid => {
      data_type => 'integer', is_auto_increment => TRUE, is_nullable => FALSE,
      label => 'Track ID'
   },
   cdid => {
      data_type => 'integer', is_foreign_key => TRUE, is_nullable => FALSE,
      label => 'CD', display => 'cd.title'
   },
   title => { data_type => 'text', is_nullable => FALSE, label => 'Title' },
);

$class->set_primary_key('trackid');

$class->add_unique_constraint('track_title_cdid', ['title', 'cdid']);

$class->belongs_to(
   cd => "${result}::Cd",
   { cdid => 'cdid' },
   { is_deferrable => FALSE, on_delete => 'CASCADE', on_update => 'CASCADE' },
);

$class->has_many(
   'lists' => "${result}::ListTrack", { 'foreign.trackid' => 'self.trackid' }
);

1;
