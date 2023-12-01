package MCat::Model::Logfile;

use HTML::StateTable::Constants qw( EXCEPTION_CLASS FALSE TRUE );
use Type::Utils                 qw( class_type );
use MCat::Util                  qw( redirect2referer );
use Unexpected::Functions       qw( Unspecified NotFound );
use MCat::Redis;
use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'logfile';

has 'redis' => is => 'lazy', isa => class_type('MCat::Redis'), default => sub {
   my $self = shift;

   return MCat::Redis->new(
      client_name => $self->config->prefix . '_logfile_cache',
      config => $self->config->redis
   );
};

sub base : Auth('admin') {
   my ($self, $context, $logfile) = @_;

   my $nav = $context->stash('nav')->list('logfile');

   $nav->item('logfile/view', [$logfile]) if $logfile;

   $nav->finalise;
   return;
}

sub clear_cache : Auth('admin') {
   my ($self, $context, $api_ns, $logfile) = @_;

   return $self->error($context, Unspecified, ['logfile']) unless $logfile;

   return unless $self->has_valid_token($context);

   my $path = $context->config->logfile->parent->catfile("${logfile}.log");

   return $self->error($context, NotFound, ["${path}"]) unless $path->exists;

   $self->redis->del($_) for ($self->redis->keys("${path}!*"));

   my $message = ['Cache cleared [_1]', "${path}"];

   $context->stash(redirect2referer $context, $message);
   return;
}

sub list : Auth('admin') Nav('Logfiles') {
   my ($self, $context) = @_;

   my $options = { context => $context };

   $context->stash(table => $self->new_table('Logfile::List', $options));
   return;
}

sub view : Auth('admin') Nav('View Logfile') {
   my ($self, $context, $logfile) = @_;

   return $self->error($context, Unspecified, ['logfile']) unless $logfile;

   my $options = {
      caption => "${logfile} Logfile View",
      context => $context,
      logfile => $logfile,
      redis   => $self->redis
   };
   $context->stash(table => $self->new_table('Logfile::View', $options));
   return;
}

1;
