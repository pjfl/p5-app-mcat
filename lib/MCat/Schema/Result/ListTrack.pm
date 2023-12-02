package MCat::Schame::Result::ListTrack;

use strictures;
use parent 'DBIx::Class::Core';

use HTML::Forms::Constants qw( FALSE TRUE );

my $class = __PACKAGE__;

$class->table('list.track');

$class->add_columns(
   trackid => { data_type => 'integer' },
   list_id => { data_type => 'integer' },
);

$class->set_primary_key(qw( trackid list_id ));

$class->belongs_to(
   tracks => 'MCat::Schema::Result::Track',
   { 'foreign.trackid' => 'self.trackid' }
);

$class->belongs_to(
   list => 'MCat::Schema::Result::List',
   { 'foreign.id' => 'self.list_id' }
);

1;
