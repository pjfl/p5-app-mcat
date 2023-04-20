package MCat::Schema;

use strictures;
use parent 'DBIx::Class::Schema';

use MCat; our $VERSION = MCat->schema_version;
use MCat::Config; # Set exception class
use Scalar::Util qw( weaken );

my $class = __PACKAGE__;

$class->load_namespaces;
$class->load_components('Schema::Versioned');

my $config;

sub config {
   my ($self, $value) = @_;

   $config = $value if $value;

   $self->upgrade_directory($config->sqldir->as_string);

   return $config;
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

1;
