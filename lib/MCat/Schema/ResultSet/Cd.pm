package MCat::Schema::ResultSet::Cd;

use Moo;

extends 'DBIx::Class::ResultSet';

sub find_by_key {
   my ($self, $key, $options) = @_;

   return unless $key;

   return $self->find($key, $options // {}) if $key =~ m{ \A \d+ \z }mx;

   return $self->search({ 'me.title' => $key }, $options // {})->single;
}

use namespace::autoclean;

1;
