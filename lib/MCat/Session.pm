package MCat::Session;

use HTML::StateTable::Constants qw( FALSE TRUE );
use Class::Usul::Cmd::Types     qw( ConfigProvider );
use Plack::Session::State::Cookie;
use Plack::Session::Store::Cache;
use Moo;

with 'MCat::Role::JSONParser';

has 'config' => is => 'ro', isa => ConfigProvider, required => TRUE;

with 'MCat::Role::Redis';

has '+redis_client_name' => is => 'ro', default => 'session_store';

sub middleware_config {
   my $self   = shift;
   my $config = $self->config->state_cookie;

   return (
      state => Plack::Session::State::Cookie->new(@{$config}),
      store => Plack::Session::Store::Cache->new(cache => $self),
   );
}

sub get {
   my ($self, $key) = @_;

   return $self->json_parser->decode($self->redis_client->get($key));
}

sub remove {
   my ($self, $key) = @_;

   return $self->redis_client->del($key);
}

sub set {
   my ($self, $key, $value) = @_;

   return $self->redis_client->set($key, $self->json_parser->encode($value));
}

use namespace::autoclean;

1;
