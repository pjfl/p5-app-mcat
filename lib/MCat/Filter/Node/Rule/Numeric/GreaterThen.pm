package MCat::Filter::Node::Rule::Numeric::GreaterThan;

use Moo;

extends 'MCat::Filter::Node::Rule::Numeric';

has '+_operator' => default => '>';

use namespace::autoclean;

1;
