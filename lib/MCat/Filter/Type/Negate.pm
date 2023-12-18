package MCat::Filter::Type::Negate;

use Moo;

extends 'MCat::Filter::Node';

has 'negate' => is => 'ro';

sub value {}

1;
