package MCat::Schema;

use strictures;
use parent 'DBIx::Class::Schema';

use MCat; our $VERSION = MCat->schema_version;
use MCat::Config; # Set exception class
use Scalar::Util qw( weaken );

my $class = __PACKAGE__;

$class->load_namespaces;
#$class->load_components('Schema::Versioned');

my $config;

sub config {
   my ($self, $value) = @_;

   $config = $value if defined $value;

   $self->upgrade_directory($config->sqldir->as_string)
      if $self->can('upgrade_directory');

   return $config;
}

sub jobdaemon {
   my ($self, $value) = @_;

   if (defined $value) {
      weaken $value; $self->{_jobdaemon} = $value;
   }

   return $self->{_jobdaemon};
}

sub create_ddl_dir {
   my ($self, @args) = @_;

   local $SIG{__WARN__} = sub {
      my $error = shift;
      warn "${error}\n"
         unless $error =~ m{ Overwriting \s existing \s DDL \s file }mx;
      return 1;
   };

   return $self->SUPER::create_ddl_dir(@args);
}

sub deploy {
   my ($self, $sqltargs, $dir) = @_;

   $self->throw_exception("Can't deploy without storage") unless $self->storage;

   eval {
      $self->storage->_get_dbh->do('DROP TABLE dbix_class_schema_versions');
   };

   $self->storage->deploy($self, undef, $sqltargs, $dir);
   return;
}

1;
