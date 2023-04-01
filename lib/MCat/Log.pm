package MCat::Log;

use HTML::Forms::Constants qw( FALSE TRUE );
use HTML::Forms::Types     qw( Bool );
use MCat::Util             qw( now );
use Ref::Util              qw( is_arrayref is_coderef );
use Type::Utils            qw( class_type );
use Moo;

has 'config' => is => 'ro', isa => class_type('MCat::Config'), required => TRUE;

has '_debug' => is => 'lazy', isa => Bool, init_arg => 'debug', default => sub {
   my $self = shift;
   my $env  = $ENV{ uc $self->config->appclass . '_debug' };

   return defined $env ? !!$env : FALSE;
};

around 'BUILDARGS' => sub {
   my ($orig, $self, @args) = @_;

   my $attr = $orig->($self, @args);

   if (my $builder = delete $attr->{builder}) {
      $attr->{config} = $builder->config;
      $attr->{debug} = $builder->debug;
   }

   return $attr;
};

sub alert {
   return shift->_log('ALERT', $_[0]);
}

sub debug {
   my $self = shift;

   return unless $self->_debug;

   return $self->_log('DEBUG', $_[0]);
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

sub log { # For benefit of P::M::LogDispatch
   my ($self, %args) = @_;

   my $level   = uc $args{level};
   my $message = $args{message};
   my $name    = $args{name} || (split m{ :: }mx, caller)[-1];

   return if $level =~ m{ debug }imx && !$self->_debug;

   $message = $message->() if is_coderef $message;
   $message = is_arrayref $message ? $message->[0] : $message;

   return $self->_log($level, "${name}: ${message}");
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
