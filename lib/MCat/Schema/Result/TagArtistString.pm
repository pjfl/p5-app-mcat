package MCat::Schema::Result::TagArtistString;

use strictures;
use parent 'DBIx::Class::Core';

use HTML::Forms::Constants qw( FALSE TRUE );

my $class = __PACKAGE__;

$class->table('tag.artist_string');

$class->add_columns(
   artistid => { data_type => 'integer' },
   name     => { data_type => 'text' },
);

$class->set_primary_key(qw( artistid ));

$class->belongs_to(
   artists => 'MCat::Schema::Result::Artist',
   { 'foreign.artistid' => 'self.artistid' }
);

1;
