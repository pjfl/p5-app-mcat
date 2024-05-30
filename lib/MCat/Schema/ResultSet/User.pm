package MCat::Schema::ResultSet::User;

use HTML::Forms::Constants qw( FALSE TRUE );
use Moo;

extends 'DBIx::Class::ResultSet';

sub active {
   my $self = shift; return $self->search({ active => TRUE });
}

sub find_by_key {
   my ($self, $key, $options) = @_;

   return unless $key;

   return $self->find($key, $options // {}) if $key =~ m{ \A \d+ \z }mx;

   my $select = [ { 'me.name' => $key }, { 'me.email' => $key } ];

   return $self->search({ -or => $select }, $options // {})->single;
}

1;
