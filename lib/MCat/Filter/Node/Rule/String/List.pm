package MCat::Filter::Node::Rule::String::List;

use Moo;

extends 'MCat::Filter::Node::Rule::String';

has '+_operator' => default => '=';

use namespace::autoclean;

1;
