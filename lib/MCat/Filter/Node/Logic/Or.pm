package MCat::Filter::Node::Logic::Or;

use Moo;

extends 'MCat::Filter::Node::Logic';

sub to_abstract {
   my ($self, $args) = @_;

   # Nodes are arrays for ors and hashes for ands. Each sets join type
   return '-or' => [ map { $_->to_abstract($args) } @{$self->nodes} ];
}

use namespace::autoclean;

1;
