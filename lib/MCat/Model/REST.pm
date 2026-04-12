package MCat::Model::REST;

use MCat::Constants qw( FALSE TRUE );
use Moo;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'rest';

sub authorise : Auth('none') {
   my ($self, $context) = @_;

   my $api = $context->controllers->{rest}->api;

   $self->_stash_response($context, $api->authorise($context));
   return;
}

sub access_token : Auth('none') {
   my ($self, $context) = @_;

   my $api = $context->controllers->{rest}->api;

   $self->_stash_response($context, $api->access_token($context));
   return;
}

sub refresh : Auth('none') {
   my ($self, $context) = @_;

   my $api = $context->controllers->{rest}->api;

   $self->_stash_response($context, $api->refresh($context));
   return;
}

sub dispatch : Auth('none') {
   my ($self, $context, @args) = @_;

   my $api = $context->controllers->{rest}->api;

   $self->_stash_response($context, $api->dispatch($context, @args));
   return;
}

# Private methods
sub _stash_response {
   my ($self, $context, $response) = @_;

   $context->stash(code => $response->[0], json => $response->[1]);
   $context->stash(finalised => TRUE, view => 'json');
   return;
}

1;
