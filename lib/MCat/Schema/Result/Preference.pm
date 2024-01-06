package MCat::Schema::Result::Preference;

use HTML::Forms::Constants qw( FALSE TRUE );
use JSON::MaybeXS          qw( decode_json encode_json );
use DBIx::Class::Moo::ResultClass;

my $class  = __PACKAGE__;
my $result = 'MCat::Schema::Result';

$class->table('preference');

$class->add_columns(
   id      => {
      data_type => 'integer', is_auto_increment => TRUE, is_nullable => FALSE
   },
   user_id => {
      data_type => 'integer', is_nullable => FALSE, label => 'User',
      display   => 'user.name'
   },
   name    => { data_type => 'text', is_nullable => FALSE },
   value   => { data_type => 'text', is_nullable => TRUE },
);

$class->set_primary_key('id');

$class->add_unique_constraint(
   'preference_user_id_name_uniq', ['user_id', 'name']
);

$class->belongs_to('user' => "${result}::User", 'user_id');

$class->inflate_column('value', {
   deflate => sub { encode_json(shift) },
   inflate => sub { decode_json(shift) },
});

sub preference {
   my ($self, $name, $value) = @_;

   $self->value->{$name} = $value if defined $value;

   return $self->value->{$name};
}

1;
