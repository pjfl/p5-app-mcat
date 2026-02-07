package MCat::Plack::Loader;

use strictures;
use parent 'Plack::Loader';

use English             qw( -no_match_vars );
use File::DataClass::IO qw( io );

sub preload_app {
   my ($self, $builder) = @_;

   $self->{builder} = $builder;
   return;
}

sub run {
   my ($self, $server) = @_;

   my $pidfile = $ENV{PLACK_PIDFILE} ? io($ENV{PLACK_PIDFILE}) : q();

   $pidfile->print($PID)->flush->close if $pidfile;

   $self->_fork_and_start($server);

   return unless $self->{pid};

   local $SIG{HUP}  = sub { $self->_restart($server) };
   local $SIG{TERM} = sub { $self->_kill_child };

   wait;

   $pidfile->unlink if $pidfile;

   return;
}

# Private methods
sub _fork_and_start {
   my ($self, $server) = @_;

   delete $self->{pid}; # re-init in case it's a restart

   my $pid = fork;

   die "Cannot fork: ${ERRNO}" unless defined $pid;

   if ($pid == 0) { $server->run($self->{builder}->()) }
   else { $self->{pid} = $pid }

   return;
}

sub _kill_child {
   my $self = shift;
   my $pid  = $self->{pid} or return;

   warn "Killing the existing server ${pid}\n";
   kill 'TERM', $pid;
   waitpid $pid, 0;
   return;
}

sub _restart {
   my ($self, $server) = @_;

   $self->_kill_child;
   warn "Successfully killed! Restarting the new server process.\n";
   $self->_fork_and_start($server);
   return;
}

use namespace::autoclean;

1;
