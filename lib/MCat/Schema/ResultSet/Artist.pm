package MCat::Schema::ResultSet::Artist;

use HTML::Forms::Constants qw( TRUE );
use Moo;

extends 'DBIx::Class::ResultSet';

sub active {
   my $self = shift; return $self->search({ active => TRUE });
}

1;
