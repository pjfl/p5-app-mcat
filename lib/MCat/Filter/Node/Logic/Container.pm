package MCat::Filter::Node::Logic::Container;

use Moo;

extends 'MCat::Filter::Node::Logic';

sub to_where {
   my ($self, $args) = @_;

   return { map { $_->to_where($args) } @{$self->nodes} };
}

use namespace::autoclean;

1;
