package MCat::Role::Config;

use Class::Usul::Cmd::Constants qw( TRUE );
use Class::Usul::Cmd::Types     qw( ConfigProvider );
use Scalar::Util                qw( blessed );
use MCat::Config;
use Moo::Role;

has 'config' => is => 'ro', isa => ConfigProvider, required => TRUE;

around 'BUILDARGS' => sub {
   my ($orig, $self, @args) = @_;

   my $attr   = $orig->($self, @args);
   my $config = $attr->{config} // { appclass => 'MCat' };

   $attr->{config} = MCat::Config->new($config) unless blessed $config;

   return $attr;
};

use namespace::autoclean;

1;
