package MCat::Model::Logfile;

use HTML::StateTable::Constants qw( EXCEPTION_CLASS );
use MCat::Util                  qw( redirect );
use Unexpected::Functions       qw( Unspecified );
use Web::Simple;

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'logfile';

sub base {
   my ($self, $context) = @_;

   $context->stash('nav')->list('logfile', 'Logfiles');
   return;
}

sub list {
   my ($self, $context) = @_;

   my $options = { context => $context };

   $context->stash(
      table => $self->table->new_with_context('Logfile::List', $options)
   );
   return;
}

sub view {
   my ($self, $context, $logfile) = @_;

   return $self->error($context, Unspecified, ['logfile']) unless $logfile;

   my $options = { context => $context, logfile => $logfile };

   $context->stash(
      table => $self->table->new_with_context('Logfile::View', $options)
   );
   return;
}

use namespace::autoclean;

1;
