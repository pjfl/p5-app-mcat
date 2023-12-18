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

has '_template' => is => 'ro', isa => Str, default => '\%s::integer';

sub value {
   my $self = shift;
   my $value = $self->number->value;

   $value =~ s{ [^.0-9-] }{}gmx;

   return $value;
}

sub _to_where {
   my ($self, $args) = @_;

   my $lhs = sprintf $self->_template, $self->field->name($args);

   return { $lhs => { $self->_operator => $self->value } };

}

use namespace::autoclean;

1;
