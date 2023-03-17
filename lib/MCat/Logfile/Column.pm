package MCat::Logfile::Column;

use HTML::StateTable::Constants qw( FALSE TRUE );
use HTML::StateTable::Types     qw( Iterable Str );
use Moo;

has 'name' => is => 'ro', isa => Str, required => TRUE;

has 'resultset' => is => 'ro', isa => Iterable, required => TRUE;

sub all {
   my $self   = shift;
   my $name   = $self->name;
   my @values = ();

   while (my $result = $self->resultset->next) {
      push @values, $result->$name;
   }

   $self->resultset->reset;
   return @values;
}

use namespace::autoclean;

1;
