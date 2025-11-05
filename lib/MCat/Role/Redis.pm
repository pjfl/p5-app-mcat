package MCat::Role::Redis;

use Class::Usul::Cmd::Constants qw( FALSE TRUE );
use Unexpected::Types           qw( Str );
use Type::Utils                 qw( class_type );
use MCat::Redis;
use Moo::Role;

has 'redis_client' =>
   is      => 'lazy',
   isa     => class_type('MCat::Redis'),
   default => sub {
      my $self   = shift;
      my $config = $self->config;
      my $name   = $config->prefix . '_' . $self->redis_client_name;

      return MCat::Redis->new(
         client_name => $name, config => $config->redis
      );
   };

has 'redis_client_name' => is => 'ro', isa => Str, default => 'unknown';

use namespace::autoclean;

1;
