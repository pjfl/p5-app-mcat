package MCat::Filter::Node::Rule::Date;

use HTML::Forms::Constants qw( FALSE TRUE );
use HTML::Forms::Types     qw( Str );
use MCat::Filter::Types    qw( FilterField FilterDate );
use Moo;

extends 'MCat::Filter::Node::Rule';

has 'date' => is => 'ro', isa => FilterDate, coerce => TRUE, required => TRUE;

has 'date_field_format' => is => 'ro', isa => Str, default => 'YYYY-MM-DD';

has 'field' => is => 'ro', isa => FilterField, coerce => TRUE, required => TRUE;

has '_operator' => is => 'ro', isa => Str, required => TRUE;

sub _to_abstract {
   my ($self, $args) = @_;

   my $lhs = $self->field->value;

   return $lhs => { $self->_operator => $self->_rhs_value($args) };
}

sub _rhs_value {
   my ($self, $args) = @_;

   my $value = $self->date->value;

   return sprintf "\\to_timestamp(%s, 'YYYY-MM-DD HH:MI:SS')", $value
      if $self->date->has_time_zone;

   my $format = $args->{date_field_format} || $self->date_field_format;

   return sprintf "\\to_date(%s, '%s')", $value, $format if $format;

   return "'" . $value . "'";
}

use namespace::autoclean;

1;
