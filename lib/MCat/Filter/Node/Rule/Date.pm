package MCat::Filter::Node::Rule::Date;

use HTML::Forms::Constants qw( FALSE TRUE );
use HTML::Forms::Types     qw( Str );
use MCat::Filter::Types    qw( FilterField FilterDate );
use Ref::Util              qw( is_scalarref );
use Moo;

extends 'MCat::Filter::Node::Rule';

has 'date' => is => 'ro', isa => FilterDate, coerce => TRUE, required => TRUE;

has 'date_format' => is => 'ro', isa => Str, default => 'YYYY-MM-DD';

has 'field' => is => 'ro', isa => FilterField, coerce => TRUE, required => TRUE;

has 'timestamp_format' =>
   is      => 'ro',
   isa     => Str,
   default => 'YYYY-MM-DD HH24:MI:SS';

has '_operator' => is => 'ro', isa => Str, required => TRUE;

sub _to_abstract {
   my ($self, $args) = @_;

   my $lhs = $self->field->value;

   return $lhs => { $self->_operator => $self->_rhs_value($args) };
}

sub _rhs_value {
   my ($self, $args) = @_;

   my ($holder, @values)  = $self->date->value;
   my $format = $args->{timestamp_format} || $self->timestamp_format;

   return \[ sprintf("to_timestamp(%s::text, '%s')", $holder, $format), @values]
      if $self->date->has_time_zone;

   $format = $args->{date_format} || $self->date_format;

   return \[ sprintf("to_date(%s::text, '%s')", $holder, $format), @values ]
      if $format;

   return $holder;
}

use namespace::autoclean;

1;
