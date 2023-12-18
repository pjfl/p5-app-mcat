package MCat::Filter::Node::Rule;

use HTML::Forms::Constants qw( EXCEPTION_CLASS );
use MCat::Filter::Types    qw( FilterNegate );
use Unexpected::Functions  qw( throw );
use Moo;

extends 'MCat::Filter::Node';

has 'negate' =>
   is        => 'ro',
   isa       => FilterNegate,
   handles   => { is_negated => 'negate' },
   predicate => 'has_negate';

sub to_where {
   my ($self, $args) = @_;

   my $result = $self->_to_where($args);

   return $result unless $self->has_negate && $self->is_negated;

   for my $field (keys %{$result}) {
      for my $operator (keys %{$result->{$field}}) {
         my $negated = $self->_negate($operator);

         $result->{$field}->{$negated} = delete $result->{$field}->{$operator};
      }
   }

   return $result;
}

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

sub _to_where { ... }

use namespace::autoclean;

1;
