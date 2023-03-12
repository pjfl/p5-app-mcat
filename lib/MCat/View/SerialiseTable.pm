package MCat::View::SerialiseTable;

use Moo;

extends 'HTML::StateTable::View::Serialise';
with    'Web::Components::Role';

has '+moniker' => default => 'serialise_table';

sub serialize {
   my ($self, $context) = @_;

   $self->process($context);

   my $stash  = $context->stash;
   my @header = $context->response->header;

   return [ $stash->{code}, [@header], [$context->response->body] ];
}

1;
