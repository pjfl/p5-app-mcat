package MCat::Model::Logfile;

use HTML::StateTable::Constants qw( EXCEPTION_CLASS FALSE TRUE );
use Type::Utils                 qw( class_type );
use Unexpected::Functions       qw( Unspecified );
use MCat::Redis;
use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'logfile';

has 'redis' => is => 'lazy', isa => class_type('MCat::Redis'), default => sub {
   my $self = shift;

   return MCat::Redis->new(
      client_name => 'logfile_cache', config => $self->config->redis
   );
};

sub base {
   my ($self, $context) = @_;

   $context->stash('nav')->list('logfile')->finalise;
   return;
}

sub list : Nav('Logfiles') {
   my ($self, $context) = @_;

   $context->stash(table => $self->table->new_with_context('Logfile::List', {
      context => $context
   }));
   return;
}

sub view : Nav('View Logfile') {
   my ($self, $context, $logfile) = @_;

   return $self->error($context, Unspecified, ['logfile']) unless $logfile;

   $context->stash(table => $self->table->new_with_context('Logfile::View', {
      context => $context, logfile => $logfile, redis => $self->redis
   }));
   return;
}

1;
