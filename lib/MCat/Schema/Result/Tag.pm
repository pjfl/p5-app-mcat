package MCat::Schema::Result::Tag;

use HTML::Forms::Constants qw( FALSE TRUE );
use DBIx::Class::Moo::ResultClass;

my $class  = __PACKAGE__;
my $result = 'MCat::Schema::Result';

$class->table('tag');

$class->add_columns(
   id => {
      data_type         => 'integer',
      is_auto_increment => TRUE,
      is_nullable       => FALSE,
      label             => 'Tag ID'
   },
   name => { data_type => 'text', is_nullable => FALSE, label => 'Name' },
);

$class->set_primary_key('id');

$class->add_unique_constraint('tag_name_uniq', ['name']);

$class->has_many(
   artist_tags => "${result}::TagArtist", { 'foreign.tag_id' => 'self.id' },
);

1;
