package MCat::Schema::Result::ListArtist;

use HTML::Forms::Constants qw( FALSE TRUE );
use DBIx::Class::Moo::ResultClass;

my $class  = __PACKAGE__;
my $result = 'MCat::Schema::Result';

$class->table('list.artist');

$class->add_columns(
   artistid => { data_type => 'integer' },
   list_id  => { data_type => 'integer' },
);

$class->set_primary_key(qw( artistid list_id ));

$class->belongs_to(
   'artists' => "${result}::Artist", { 'foreign.artistid' => 'self.artistid' }
);

$class->belongs_to(
   'lists' => "${result}::List", { 'foreign.id' => 'self.list_id' }
);

1;
