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

sub _to_abstract {
   my ($self, $args) = @_;

   my ($lhs, $value);

   if ($args->{insensitive}) {
      $lhs = sprintf $self->_template, $self->field->value($args);
      $value = lc $self->string->value;
   }
   else {
      $lhs = $self->field->value($args);
      $value = $self->string->value;
   }

   return $lhs => { $self->_operator => $value };
}

use namespace::autoclean;

1;
