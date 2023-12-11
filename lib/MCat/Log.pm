package MCat::Log;

use HTML::Forms::Constants  qw( DOT FALSE TRUE USERNAME );
use Class::Usul::Cmd::Types qw( ConfigProvider );
use HTML::Forms::Types      qw( Bool );
use Class::Usul::Cmd::Util  qw( now_dt ns_environment );
use Ref::Util               qw( is_arrayref is_coderef );
use Moo;

has 'config' => is => 'ro', isa => ConfigProvider, required => TRUE;

has '_debug' =>
   is       => 'lazy',
   isa      => Bool,
   init_arg => 'debug',
   default  => sub {
      my $self = shift;
      my $env  = ns_environment $self->config->appclass, 'debug';

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
   my $leader  = $args{name} || (split m{ :: }mx, caller)[-1];

   return if $level =~ m{ debug }imx && !$self->_debug;

   $message = $message->() if is_coderef $message;
   $message = is_arrayref $message ? $message->[0] : $message;

   return $self->_log($level, "${leader}: ${message}");
}

sub warn {
   return shift->_log('WARNING', @_);
}

# Private methods
sub _get_leader {
   my ($self, $context) = @_;

   my $leader = 'Unknown';

   return $leader unless $context;

   if ($context->can('leader')) { $leader = $context->leader }
   elsif ($context->can('action') && $context->has_action) {
      my @parts = split m{ / }mx, ucfirst $context->action;

      $leader = $parts[0] . DOT . $parts[-1];
   }
   elsif ($context->can('name')) { $leader = ucfirst $context->name }

   return $leader;
}

sub _log {
   my ($self, $level, $message, $context) = @_;

   $message //= 'Unknown';
   $message = "${message}";
   chomp $message;

   $message = $self->_get_leader($context) . ": ${message}"
      if $message !~ m{ : }mx;

   my $now      = now_dt->strftime('%Y/%m/%d %T');
   my $username = $context && $context->can('session')
      ? $context->session->username : USERNAME;

   $message = "${now} [${level}] (${username}) ${message}\n";

   if (my $file = $self->config->logfile) { $file->append($message)->flush }
   else { CORE::warn $message }

   return TRUE;
}

use namespace::autoclean;

1;
