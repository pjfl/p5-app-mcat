package MCat::Plack::Loader;

use English             qw( -no_match_vars );
use File::DataClass::IO qw( io );
use MCat;
use Moo;

extends 'Plack::Loader';

sub run {
   my($self, $server) = @_;

   my $pidfile = MCat->env_var('web_server');

   if ($pidfile) {
      $pidfile = io $pidfile;
      $pidfile->print($PID)->flush->close;
   }

   $self->_fork_and_start($server);

   return unless $self->{pid};

   local $SIG{HUP}  = sub { $self->_restart($server) };
   local $SIG{TERM} = sub { $self->_kill_child; exit(0) };

   wait;

   $pidfile->unlink if $pidfile;

   return;
}

# Private methods
sub _fork_and_start {
   my($self, $server) = @_;

   delete $self->{pid}; # re-init in case it's a restart

   my $pid = fork;

   die "Can't fork: ${ERRNO}" unless defined $pid;

   if ($pid == 0) { $server->run($self->{app}) }
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
