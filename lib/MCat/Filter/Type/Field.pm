package MCat::Filter::Type::Field;

use HTML::Forms::Constants qw( FALSE TRUE );
use HTML::Forms::Types     qw( Str );
use Moo;

has 'schema' => is => 'ro', isa => Str, predicate => 'has_schema';

has '_name' => is => 'ro', isa => Str, init_arg => 'name', required => TRUE;

sub name {
   my ($self, $args) = @_;

   $args //= {};

   my $schema = $args->{schema} || 'public';

   $schema = $self->schema if $self->has_schema;

   return sprintf '"%s"."%s"', $schema, $self->name;
}

use namespace::autoclean;

1;
