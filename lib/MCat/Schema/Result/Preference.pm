package MCat::Schema::Result::Preference;

use strictures;
use parent 'DBIx::Class::Core';

use HTML::Forms::Constants qw( FALSE TRUE );
use JSON::MaybeXS          qw( decode_json encode_json );

my $class = __PACKAGE__;

$class->table('preference');

$class->add_columns(
   id    => {
      data_type => 'integer', is_auto_increment => TRUE, is_nullable => FALSE
   },
   name  => { data_type => 'text', is_nullable => FALSE },
   value => { data_type => 'text', is_nullable => TRUE },
);

$class->set_primary_key('id');

$class->add_unique_constraint('preference_name', ['name']);

$class->inflate_column('value', {
   deflate => sub { encode_json(shift) },
   inflate => sub { decode_json(shift) },
});

1;

