package MCat::View::SerialiseTable;

use HTML::StateTable::Constants qw( SERIALISE_TABLE_VIEW );
use Moo;

extends 'HTML::StateTable::View::Serialise';
with    'Web::Components::Role';

has '+moniker' => default => SERIALISE_TABLE_VIEW;

sub serialize {
   my ($self, $context) = @_;

   $self->process($context);

   my $stash  = $context->stash;
   my @header = $context->response->header;

   return [ $stash->{code}, [@header], [$context->response->body] ];
}

use namespace::autoclean;

1;
