package MCat::Session;

use HTML::StateTable::Constants qw( FALSE TRUE );
use Class::Usul::Cmd::Types     qw( ConfigProvider );
use Type::Utils                 qw( class_type );
use JSON::MaybeXS               qw( );
use Plack::Session::State::Cookie;
use Plack::Session::Store::Cache;
use Moo;

has 'config' => is => 'ro', isa => ConfigProvider, required => TRUE;

with 'MCat::Role::Redis';

has '+redis_client_name' => is => 'ro', default => 'session_store';

has '_json' =>
   is      => 'ro',
   isa     => class_type(JSON::MaybeXS::JSON),
   default => sub { JSON::MaybeXS->new( convert_blessed => TRUE ) };

sub middleware_config {
   my $self = shift;

   return (
      state => Plack::Session::State::Cookie->new(
         expires     => 7_776_000,
         httponly    => TRUE,
         path        => $self->config->mount_point,
         samesite    => 'None',
         secure      => TRUE,
         session_key => $self->config->prefix.'_session',
      ),
      store => Plack::Session::Store::Cache->new(cache => $self)
   );
}

sub get {
   my ($self, $key) = @_;

   return $self->_json->decode($self->redis_client->get($key));
}

sub remove {
   my ($self, $key) = @_;

   return $self->redis_client->del($key);
}

sub set {
   my ($self, $key, $value) = @_;

   return $self->redis_client->set($key, $self->_json->encode($value));
}

use namespace::autoclean;

1;
