package MCat::Log;

use HTML::Forms::Constants qw( FALSE TRUE );
use HTML::Forms::Util      qw( now );
use Type::Utils            qw( class_type );
use Moo;

has 'config' => is => 'ro', isa => class_type('MCat::Config');

sub alert {
   return shift->_log('ALERT', $_[0]);
}

sub debug {
   return shift->_log('DEBUG', $_[0]);
}

sub error {
   return shift->_log('ERROR', $_[0]);
}

sub fatal {
   return shift->_log('FATAL', $_[0]);
}

sub info {
   return shift->_log('INFO', $_[0]);
}

sub warn {
   return shift->_log('WARNING', $_[0]);
}

sub _log {
   my ($self, $level, $message) = @_;

   my $now = now->strftime('%Y/%m/%d %T');

   $message = "${message}"; chomp $message;
   $message = "${now} [${level}] ${message}\n";

   if ($self->config->logfile) {
      $self->config->logfile->append($message)->flush;
   }
   else { CORE::warn $message }

   return TRUE;
}

use namespace::autoclean;

1;
