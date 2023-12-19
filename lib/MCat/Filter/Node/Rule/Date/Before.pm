package MCat::Filter::Node::Rule::Date::Before;

use Moo;

extends 'MCat::Filter::Node::Rule::Date';

has '+_operator' => default => '<';

use namespace::autoclean;

1;
