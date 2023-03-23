package MCat::Model::Logfile;

use HTML::StateTable::Constants qw( EXCEPTION_CLASS );
use MCat::Util                  qw( redirect );
use Unexpected::Functions       qw( Unspecified );
use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'logfile';

sub base {
   my ($self, $context) = @_;

   $context->stash('nav')->list('logfile');
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
      context => $context, logfile => $logfile
   }));
   return;
}

1;
