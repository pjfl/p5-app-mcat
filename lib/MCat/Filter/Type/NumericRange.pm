package MCat::Filter::Type::NumericRange;

use HTML::Forms::Constants qw( FALSE TRUE );
use HTML::Forms::Types     qw( Maybe Num );
use Moo;

extends 'MCat::Filter::Node';

has 'max_value' => is => 'ro', isa => Maybe[Num];

has 'min_value' => is => 'ro', isa => Maybe[Num];

sub value {
   my $self = shift;
   my @values;

   push @values, $self->max_value if $self->max_value;
   push @values, $self->min_value if $self->min_value;

   return @values;
}

use namespace::autoclean;

1;
