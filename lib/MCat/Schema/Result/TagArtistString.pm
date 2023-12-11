package MCat::Schema::Result::TagArtistString;

use HTML::Forms::Constants qw( FALSE TRUE );
use DBIx::Class::Moo::ResultClass;

my $class  = __PACKAGE__;
my $result = 'MCat::Schema::Result';

$class->table('tag.artist_string');

$class->add_columns(
   artistid => { data_type => 'integer' },
   name     => { data_type => 'text' },
);

$class->set_primary_key(qw( artistid ));

$class->belongs_to(
   artists => "${result}::Artist", { 'foreign.artistid' => 'self.artistid' }
);

1;
