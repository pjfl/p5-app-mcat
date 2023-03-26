package MCat::Session;

use HTML::StateTable::Constants qw( FALSE TRUE );
use HTML::StateTable::ResultSet::Redis;
use JSON::MaybeXS qw( decode_json encode_json );
use Plack::Session::State::Cookie;
use Plack::Session::Store::Cache;
use Type::Utils qw( class_type );
use Moo;

has 'config' => is => 'ro', isa => class_type('MCat::Config'), required => TRUE;

has 'redis' => is => 'lazy', default => sub {
   my $self = shift;

   return HTML::StateTable::ResultSet::Redis->new(
      client_name => 'session_store', config => $self->config->redis,
   );
};

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
   my ($self, $key) = @_; return decode_json($self->redis->get($key));
}

sub remove {
   my ($self, $key) = @_; return $self->redis->del($key);
}

sub set {
   my ($self, $key, $value) = @_;

   return $self->redis->set($key, encode_json($value));
}

use namespace::autoclean;

1;
