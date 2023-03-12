package MCat::Schema::Result::Tag;

use strictures;
use parent 'DBIx::Class::Core';

use HTML::Forms::Constants qw( FALSE TRUE );

my $class = __PACKAGE__;

$class->table('tag');

$class->add_columns(
   id   => {
      data_type => 'integer', is_auto_increment => TRUE, is_nullable => FALSE
   },
   name => { data_type => 'text', is_nullable => FALSE },
);

$class->set_primary_key('id');

$class->add_unique_constraint('tag_name_uniq', ['name']);

$class->has_many(
   artist_tags => 'MCat::Schema::Result::TagArtist',
   { 'foreign.tag_id' => 'self.id' },
);

1;
