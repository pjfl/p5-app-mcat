package MCat::Filter::Node::Rule::Date::After;

use Moo;

extends 'MCat::Filter::Node::Rule::Date';

has '+_operator' => default => '>';

use namespace::autoclean;

1;
