package MCat::Filter::Node::Logic::Container;

use Moo;

extends 'MCat::Filter::Node::Logic';

sub to_abstract {
   my ($self, $args) = @_;

   return map { $_->to_abstract($args) } @{$self->nodes};
}

use namespace::autoclean;

1;
