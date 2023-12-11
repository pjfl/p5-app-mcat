package MCat::Filter::Node::Rule;

use HTML::Forms::Constants qw( EXCEPTION_CLASS );
use HTML::Forms::Types     qw( Bool );
use Unexpected::Functions  qw( throw );
use Moo;

extends 'MCat::Filter::Node';

has 'negate' => is => 'ro', isa => Bool, predicate => 'has_negate';

sub search {
   my ($self, $args) = @_;

   my $search = $self->_search($args);

   return $search unless $self->has_negate && $self->negate;

   for my $field (keys %{$search}) {
      for my $operator (keys %{$search->{$field}}) {
         my $negated = $self->_negate($operator);

         $search->{$field}->{$negated} = delete $search->{$field}->{$operator};
      }
   }

   return $search;
}

sub value {}

# Private methods
my $dispatch = {
   '=' => '!=', '!=' => '=',
   '<' => '>=', '>=' => '<',
   '>' => '<=', '<=' => '>',
};

sub _negate {
   my ($self, $operator) = @_;

   throw 'Operator [_1] unknown', [$operator]
      unless exists $dispatch->{$operator};

   return $dispatch->{$operator};
}

sub _search {}

use namespace::autoclean;

1;
