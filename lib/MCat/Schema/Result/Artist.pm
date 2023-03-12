package MCat::Schema::Result::Artist;

use strictures;
use parent 'DBIx::Class::Core';

use HTML::Forms::Constants qw( FALSE TRUE );

my $class = __PACKAGE__;

$class->load_components('InflateColumn::DateTime');

$class->table('artist');

$class->add_columns(
   artistid => {
      data_type => 'integer', is_nullable => FALSE, is_auto_increment => TRUE },
   name => { data_type => 'text', is_nullable => FALSE },
   active => { data_type => 'boolean', is_nullable => FALSE, default => TRUE },
   upvotes => { data_type => 'integer', is_nullable => FALSE, default => 0 },
);

$class->set_primary_key('artistid');

$class->add_unique_constraint('artist_name_uniq', ['name']);

$class->has_many(
  cds => 'MCat::Schema::Result::Cd',
  { 'foreign.artistid' => 'self.artistid' },
  { cascade_copy => FALSE, cascade_delete => FALSE },
);

$class->has_many(
   artist_tags => 'MCat::Schema::Result::TagArtist',
   { 'foreign.artistid' => 'self.artistid' }
);

$class->many_to_many('tags', 'artist_tags', 'tag');

$class->might_have(
   tag_string => 'MCat::Schema::Result::TagArtistString',
   { 'foreign.artistid' => 'self.artistid' }
);

1;
