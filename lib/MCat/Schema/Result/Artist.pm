package MCat::Schema::Result::Artist;

use HTML::Forms::Constants qw( FALSE TRUE );
use DBIx::Class::Moo::ResultClass;

my $class  = __PACKAGE__;
my $result = 'MCat::Schema::Result';

$class->load_components('InflateColumn::DateTime');

$class->table('artist');

$class->add_columns(
   artistid => {
      data_type => 'integer', is_nullable => FALSE, is_auto_increment => TRUE,
      label => 'Artist ID'
   },
   name => { data_type => 'text', is_nullable => FALSE, label => 'Name' },
   active => {
      data_type => 'boolean', is_nullable => FALSE, default => TRUE,
      label => 'Still Active', cell_traits => ['Bool']
   },
   upvotes => {
      data_type => 'integer', is_nullable => FALSE, default => 0,
      label => 'Upvotes'
   },
);

$class->set_primary_key('artistid');

$class->add_unique_constraint('artist_name_uniq', ['name']);

$class->has_many(
  cds => "${result}::Cd",
  { 'foreign.artistid' => 'self.artistid' },
  { cascade_copy => FALSE, cascade_delete => FALSE },
);

$class->has_many(
   artist_tags => "${result}::TagArtist",
   { 'foreign.artistid' => 'self.artistid' }
);

$class->many_to_many('tags', 'artist_tags', 'tag');

$class->might_have(
   tag_string => "${result}::TagArtistString",
   { 'foreign.artistid' => 'self.artistid' }
);

1;
