package MCat::Filter::Node::Rule::Numeric::LessThan;

use Moo;

extends 'MCat::Filter::Node::Rule::Numeric';

has '+_operator' => default => '<';

use namespace::autoclean;

1;
