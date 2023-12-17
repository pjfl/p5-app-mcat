package MCat::Filter::Node::Logic::And;

use Moo;

extends 'MCat::Filter::Node::Logic';

sub search {
   my ($self, $args) = @_;

   return { map { %{$_->search($args)} } @{$self->nodes} };
}

use namespace::autoclean;

1;