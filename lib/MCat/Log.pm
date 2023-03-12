package MCat::Log;

use HTML::Forms::Util qw( now );
use Moo;

sub error {
   my ($self, $exception) = @_;

   my $message ="${exception}"; chomp $message;
   my $now     = now;

   warn "${now} ${message}\n";
}

sub info {
   my ($self, $message) = @_;

   my $now = now;

   warn "${now} ${message}\n";
}

use namespace::autoclean;

1;
