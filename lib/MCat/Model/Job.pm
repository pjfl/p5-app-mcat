package MCat::Model::Job;

use File::DataClass::Types qw( LoadableClass );
use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE NUL TRUE );
use MCat::Util             qw( redirect redirect2referer );
use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'job';

has 'jobdaemon' => is => 'lazy', default => sub {
   my $self = shift;

   return $self->jobdaemon_class->new(config => {
      appclass => 'MCat',
      pathname => $self->config->bin->catfile('mcat-jobserver'),
   });
};

has 'jobdaemon_class' => is => 'lazy', isa => LoadableClass, coerce => TRUE,
   default => 'MCat::JobServer';

sub base : Auth('admin') {
   my ($self, $context) = @_;

   $context->stash('nav')->list('job')->finalise;

   return;
}

sub remove {
   my ($self, $context) = @_;

   return unless $self->has_valid_token($context);

   my $value = $context->request->body_parameters->{data} or return;
   my $runin = $self->jobdaemon->is_running;
   my $count = 0;

   for my $key (@{$value->{selector}}) {
      if ($runin) {
         if (my $job = $context->model('Job')->find($key)) {
            $job->delete;
            $count++;
         }
      }
      else {
         my $jdpid = $self->jobdaemon->daemon_pid;
         my $pid = $key eq $self->jobdaemon->prefix ? $jdpid : '666';

         $self->jobdaemon->lock->reset(k => $key, p => $jdpid);
         $count++;
      }
   }

   my $objects = ($runin ? 'Job' : 'Lock') . ($count > 1 ? 's' : NUL);

   $context->stash(redirect2referer $context, ["${count} ${objects} deleted"]);
   return;
}

sub status : Auth('admin') Nav('Job Status') {
   my ($self, $context) = @_;

   return $self->_status_button_handler($context) if $context->posted;

   my $options = { context => $context, jobdaemon => $self->jobdaemon };
   my $form    = $self->new_form('JobStatus', $options);

   $context->stash( form => $form );

   if ($self->jobdaemon->is_running) {
      $options = { context => $context, resultset => $context->model('Job') };
      $context->stash( table => $self->new_table('Job', $options) );
   }
   else {
      $options = { context => $context, jobdaemon => $self->jobdaemon };
      $context->stash( table => $self->new_table('JobLock', $options) );
   }

   return;
}

sub _status_button_handler {
   my ($self, $context) = @_;

   my $status = $context->uri_for_action('job/status');
   my $params = $context->get_body_parameters;
   my $action = $params->{_submit} or return;

   if ($action eq 'clear') {
      $self->jobdaemon->clear;
      $context->stash( redirect $status, ['Clearing job daemon locks']);
   }
   elsif ($action eq 'restart') {
      $self->jobdaemon->restart;
      $context->stash( redirect $status, ['Restarting job daemon']);
   }
   elsif ($action eq 'start') {
      $self->jobdaemon->start;
      $context->stash( redirect $status, ['Starting job daemon']);
   }
   elsif ($action eq 'stop') {
      $self->jobdaemon->stop;
      $context->stash( redirect $status, ['Stopping job daemon']);
   }
   elsif ($action eq 'trigger') {
      $self->jobdaemon->trigger;
      $context->stash( redirect $status, ['Triggering job daemon']);
   }

   return;
}

1;
