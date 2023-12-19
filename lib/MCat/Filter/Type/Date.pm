package MCat::Filter::Type::Date;

use HTML::Forms::Constants qw( FALSE TRUE );
use HTML::Forms::Types     qw( Str );
use Moo;

extends 'MCat::Filter::Node';

has 'string' => is => 'ro', isa => Str, required => TRUE;

has 'time_zone' => is => 'ro', predicate => 'has_time_zone';

sub value {
   return shift->string;
}

use namespace::autoclean;

1;
