package MCat::Filter::Type::MultiString;

use HTML::Forms::Constants qw( FALSE NUL TRUE );
use HTML::Forms::Types     qw( ArrayRef Str );
use Moo;

extends 'MCat::Filter::Node::Type::String';

sub value {
   my $self   = shift;
   my $string = $self->string;

   $string =~ s{ \A \s+ | \s+ \z }{}gmx;

   my $values = [ split m{ (?: \s*\r*\n\s*)+ }mx, $string ];

   return defined $values->[0] ? $values : [NUL];
}

use namespace::autoclean;

1;
