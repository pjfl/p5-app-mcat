package MCat::Filter::Type::Date;

use HTML::Forms::Constants qw( FALSE TRUE );
use HTML::Forms::Types     qw( Str );
use Moo;

extends 'MCat::Filter::Node';

has 'time_zone' => is => 'ro', predicate => 'has_time_zone';

sub value { ... }

use namespace::autoclean;

1;
