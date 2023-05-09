package MCat::Schema::ResultSet::User;

use HTML::Forms::Constants qw( FALSE TRUE );
use Moo;

extends 'DBIx::Class::ResultSet';

sub active {
   my $self = shift; return $self->search({ active => TRUE });
}

sub find_by_key {
   my ($self, $name) = @_;

   return $self->find($name, { key => 'user_name_uniq' });
}

1;
