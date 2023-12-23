package MCat::Filter::Type::Field;

use HTML::Forms::Constants qw( FALSE NUL TRUE );
use HTML::Forms::Types     qw( Str );
use Moo;

has 'schema' => is => 'ro', isa => Str, predicate => 'has_schema';

has '_name' => is => 'ro', isa => Str, init_arg => 'name', required => TRUE;

sub value {
   my ($self, $args) = @_;

   $args //= {};

   my $schema = NUL;

   $schema = $self->schema if $self->has_schema;
   $schema = $args->{schema} if $args->{schema};

   return sprintf '%s.%s', $schema, $self->_name if $schema;

   return $self->_name;
}

use namespace::autoclean;

1;
