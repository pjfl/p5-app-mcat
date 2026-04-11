package MCat::Role::Schema;

use Type::Utils qw( class_type );
use MCat::JobServer;
use Moo::Role;

has 'jobdaemon' =>
   is      => 'lazy',
   isa     => class_type('MCat::JobServer'),
   default => sub {
      my $self   = shift;
      my $config = $self->config;
      my $prefix = $config->prefix;

      return MCat::JobServer->new(config => {
         appclass => $config->appclass,
         pathname => $config->bin->catfile("${prefix}-jobserver"),
      });
   };

has 'schema' =>
   is      => 'lazy',
   isa     => class_type('DBIx::Class::Schema'),
   default => sub {
      my $self   = shift;
      my $config = $self->config;
      my $class  = $config->schema_class;
      my $schema = $class->connect(@{$config->connect_info});

      $class->config($config) if $class->can('config');

      $schema->jobdaemon($self->jobdaemon) if $schema->can('jobdaemon');

      return $schema;
   };

use namespace::autoclean;

1;
