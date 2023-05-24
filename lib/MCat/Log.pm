package MCat::Log;

use HTML::Forms::Constants qw( DOT FALSE TRUE USERNAME );
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
   return shift->_log('ALERT', @_);
}

sub debug {
   my $self = shift;

   return unless $self->_debug;

   return $self->_log('DEBUG', @_);
}

sub error {
   return shift->_log('ERROR', @_);
}

sub fatal {
   return shift->_log('FATAL', @_);
}

sub info {
   return shift->_log('INFO', @_);
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
   return shift->_log('WARNING', @_);
}

sub _log {
   my ($self, $level, $message, $context) = @_;

   $message = "${message}"; chomp $message;

   if ($message !~ m{ : }mx) {
      my $action = 'Unknown';

      if ($context) {
         if ($context->can('action') && $context->has_action) {
            $action = ucfirst $context->action;

            my @parts  = split m{ / }mx, $action;

            $action  = $parts[0] . DOT . $parts[-1];
         }
         elsif ($context->can('name')) {
            $action = ucfirst $context->name;
         }
      }

      $message = "${action}: ${message}";
   }

   my $now      = now->strftime('%Y/%m/%d %T');
   my $username = $context && $context->can('session')
      ? $context->session->username : USERNAME;

   $message = "${now} [${level}] (${username}) ${message}\n";

   if ($self->config->logfile) {
      $self->config->logfile->append($message)->flush;
   }
   else { CORE::warn $message }

   return TRUE;
}

use namespace::autoclean;

1;
