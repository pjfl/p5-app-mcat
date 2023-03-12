package MCat::Schema;

use strictures;
use parent 'DBIx::Class::Schema';

use MCat;

__PACKAGE__->load_namespaces;

sub deploy {
   my ($self, $sqltargs, $dir) = @_;

   local $SIG{__WARN__} = sub {
      my $error = shift;
      warn "${error}\n"
         unless $error =~ m{ relation \s .+ \s already \s exists }mx;
      return 1;
   };

   $self->throw_exception("Can't deploy without storage") unless $self->storage;
   $self->storage->deploy($self, undef, $sqltargs, $dir);
   return;
}

sub get_db_version {
   return $MCat::VERSION;
}

1;
