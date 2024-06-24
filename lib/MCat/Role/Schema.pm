package MCat::Role::Schema;

use Type::Utils qw( class_type );
use MCat::JobServer;
use Moo::Role;

has 'jobdaemon' =>
   is      => 'lazy',
   isa     => class_type('MCat::JobServer'),
   default => sub {
      my $self = shift;

      return MCat::JobServer->new(config => {
         appclass => $self->config->appclass,
         pathname => $self->config->bin->catfile('mcat-jobserver'),
      });
   };

has 'schema' =>
   is      => 'lazy',
   isa     => class_type('DBIx::Class::Schema'),
   default => sub {
      my $self   = shift;
      my $class  = $self->config->schema_class;
      my $schema = $class->connect(@{$self->config->connect_info});

      $class->config($self->config) if $class->can('config');

      $schema->jobdaemon($self->jobdaemon) if $schema->can('jobdaemon');

      return $schema;
   };

use namespace::autoclean;

1;
