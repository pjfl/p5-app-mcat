package MCat::Filter::Type::String;

use HTML::Forms::Constants qw( FALSE TRUE );
use HTML::Forms::Types     qw( Str );
use Moo;

extends 'MCat::Filter::Node';

has 'string' => is => 'ro', isa => Str, required => TRUE;

sub value {
   return shift->string;
}

use namespace::autoclean;

1;
