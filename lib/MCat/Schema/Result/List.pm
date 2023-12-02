package MCat::Schema::Result::List;

use strictures;
use parent 'DBIx::Class::Core';

use HTML::Forms::Constants qw( FALSE TRUE );

my $class  = __PACKAGE__;
my $result = 'MCat::Schema::Result';

$class->table('list');

$class->add_columns(
   id => {
      data_type         => 'integer',
      is_auto_increment => TRUE,
      is_nullable       => FALSE,
      label             => 'List ID'
   },
   name => { data_type => 'text', is_nullable => FALSE },
);

$class->set_primary_key('id');

$class->add_unique_constraint('list_name_uniq', ['name']);

$class->has_many(
   track_lists => "${result}::ListTrack", { 'foreign.list_id' => 'self.id' },
);

1;
