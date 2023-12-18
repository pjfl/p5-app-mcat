package MCat::Filter::Node::Logic;

use Moo;

extends 'MCat::Filter::Node::AllowChildren';

sub to_where {
   my ($self, $args) = @_;

   return 
   # Nodes are arrays for ors and hashes for ands. Each sets join type
   return $self->_join_type => [ map { $_->to_where($args) } @{$self->nodes} ];
}

use namespace::autoclean;

1;
