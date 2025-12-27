package MCat::Model::Job;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE NUL TRUE );
use MCat::Util             qw( redirect redirect2referer );
use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model'; # Jobdaemon provided by schema role applied to model
with    'Web::Components::Role';

has '+moniker' => default => 'job';

sub base : Auth('admin') {
   my ($self, $context) = @_;

   $context->stash('nav')->finalise;

   return;
}

sub remove {
   my ($self, $context) = @_;

   return unless $self->verify_form_post($context);

   my $value = $context->get_body_parameters->{data} or return;
   my $type  = 'Lock';
   my $count = 0;

   for my $key (@{$value->{selector}}) {
      if ($key =~ m{ \A \d+ \z }mx) {
         if (my $job = $context->model('Job')->find($key)) {
            $job->delete;
            $count++;
         }

         $type = 'Job';
      }
      else {
         my $jdpid = $self->jobdaemon->daemon_pid;
         my $pid = $key eq $self->jobdaemon->prefix ? $jdpid : '666';

         $self->jobdaemon->lock->reset(k => $key, p => $jdpid);
         $count++;
      }
   }

   my $objects = $type . ($count > 1 ? 's' : NUL);

   $context->stash(redirect2referer $context, ["${count} ${objects} deleted"]);
   return;
}

sub status : Auth('admin') Nav('Job Status') {
   my ($self, $context) = @_;

   return $self->_status_button_handler($context) if $context->posted;

   my $options = { context => $context, jobdaemon => $self->jobdaemon };

   $context->stash( form => $self->new_form('JobStatus', $options) );
   $context->stash( lock_table => $self->new_table('JobLock', $options) );

   $options = { context => $context, resultset => $context->model('Job') };
   $context->stash( job_table => $self->new_table('Job', $options) );
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
