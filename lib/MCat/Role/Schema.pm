package MCat::Role::Schema;

use Type::Utils qw( class_type );
use Moo::Role;

has 'schema'  => is => 'lazy', isa => class_type('DBIx::Class::Schema'),
   default => sub {
      my $self   = shift;
      my $class  = $self->config->schema_class;
      my $schema = $class->connect(@{$self->config->connect_info});

      $class->config($self->config) if $class->can('config');
      $schema->context($self) if $schema->can('context');

      return $schema;
   };

use namespace::autoclean;

1;
