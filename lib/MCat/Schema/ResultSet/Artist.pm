package MCat::Schema::ResultSet::Artist;

use HTML::Forms::Constants qw( TRUE );
use Moo;

extends 'DBIx::Class::ResultSet';

sub active {
   my $self = shift; return $self->search({ active => TRUE });
}

sub find_by_key {
   my ($self, $key, $options) = @_;

   return unless $key;

   return $self->find($key, $options // {}) if $key =~ m{ \A \d+ \z }mx;

   return $self->search({ 'me.name' => $key }, $options // {})->single;
}

1;
