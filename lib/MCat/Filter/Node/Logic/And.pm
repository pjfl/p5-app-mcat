package MCat::Filter::Node::Logic::And;

use Moo;

extends 'MCat::Filter::Node::Logic';

sub to_where {
   my ($self, $args) = @_;

   # Nodes are arrays for ors and hashes for ands. Each sets join type
   return '-and' => [ map { $_->to_where($args) } @{$self->nodes} ];
}

use namespace::autoclean;

1;
