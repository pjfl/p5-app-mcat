package MCat::Filter::Node::AllowChildren;

use HTML::Forms::Constants     qw( EXCEPTION_CLASS FALSE TRUE );
use HTML::Forms::Types         qw( ArrayRef );
use Unexpected::Functions      qw( throw Unspecified );
use Moo;

extends 'MCat::Filter::Node';

has 'nodes' => is => 'ro', isa => ArrayRef, default => sub { [] };

sub add_node {
   my ($self, $node) = @_;

   throw Unspecified, ['node'] unless $node;

   throw 'Node wrong class' unless $node->isa('MCat::Filter::Node');

   push @{$self->nodes}, $node;
   return $node;
}

sub contains_empty_nodes {
   return shift->_contains_node('MCat::Filter::Node::Rule::Empty');
}


# Private methods
sub _contains_node {
   my ($self, $node_class) = @_;

   return $self->_process_nodes($node_class => sub { TRUE });
}

sub _process_nodes {
   my ($self, %dispatch) = @_;

   for my $node (@{$self->nodes}) {
      if ($node->isa('MCat::Filter::Node::AllowChildren')) {
         return TRUE if $node->_process_nodes(%dispatch);
      }

      for my $node_class (keys %dispatch) {
         next unless $node->isa($node_class);
         return TRUE if $dispatch{$node_class}->($node);
         last;
      }
   }

   return FALSE;
}

use namespace::autoclean;

1;
