package MCat::Filter::Node::Rule::String;

use HTML::Forms::Constants qw( FALSE TRUE );
use HTML::Forms::Types     qw( Str );
use MCat::Filter::Types    qw( FilterField FilterString );
use Moo;

extends 'MCat::Filter::Node::Rule';

has 'field' => is => 'ro', isa => FilterField, coerce => TRUE, required => TRUE;

has 'string' =>
   is       => 'ro',
   isa      => FilterString,
   coerce   => TRUE,
   required => TRUE;

has '_operator' => is => 'ro', isa => Str, required => TRUE;

has '_template' =>
   is      => 'ro',
   isa     => Str,
   default => '\coalesce(lower(%s), "")';

sub value {
   return lc shift->string->value;
}

sub _to_where {
   my ($self, $args) = @_;

   my $lhs = sprintf $self->_template, $self->field->name($args);

   return { $lhs => { $self->_operator => $self->value } };
}

use namespace::autoclean;

1;
