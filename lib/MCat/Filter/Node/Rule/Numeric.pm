package MCat::Filter::Node::Rule::Numeric;

use HTML::Forms::Constants qw( FALSE TRUE );
use HTML::Forms::Types     qw( Str );
use MCat::Filter::Types    qw( FilterField FilterNumeric );
use Moo;

extends 'MCat::Filter::Node::Rule';

has 'field' => is => 'ro', isa => FilterField, coerce => TRUE, required => TRUE;

has 'number' =>
   is       => 'ro',
   isa      => FilterNumeric,
   coerce   => TRUE,
   required => TRUE;

has '_operator' => is => 'ro', isa => Str, required => TRUE;

sub _to_abstract {
   my ($self, $args) = @_;

   my $lhs = $self->field->value;

   return $lhs => { $self->_operator => $self->_rhs_value($args) };
}

sub _rhs_value {
   my ($self, $args) = @_;

   my $value = $self->number->value;

   $value =~ s{ [^.0-9-] }{}gmx;

   return $value;
}

use namespace::autoclean;

1;
