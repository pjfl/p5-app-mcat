package MCat::Schema::Result::ListTrack;

use HTML::Forms::Constants qw( FALSE TRUE );
use DBIx::Class::Moo::ResultClass;

my $class  = __PACKAGE__;
my $result = 'MCat::Schema::Result';

$class->table('list.track');

$class->add_columns(
   trackid => { data_type => 'integer' },
   list_id => { data_type => 'integer' },
);

$class->set_primary_key(qw( trackid list_id ));

$class->belongs_to(
   'tracks' => "${result}::Track", { 'foreign.trackid' => 'self.trackid' }
);

$class->belongs_to(
   'lists' => "${result}::List", { 'foreign.id' => 'self.list_id' }
);

1;
