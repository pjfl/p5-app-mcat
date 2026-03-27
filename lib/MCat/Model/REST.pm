package MCat::Model::REST;

use MCat::Constants qw( EXCEPTION_CLASS FALSE TRUE );
use Moo;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'rest';

sub access_token : Auth('none') {
   my ($self, $context) = @_;

   my $api = $context->controllers->{rest}->api;

   $self->_stash_result($context, $api->access_token($context));
   return;
}

sub authorise : Auth('none') {
   my ($self, $context) = @_;

   my $api = $context->controllers->{rest}->api;

   $self->_stash_result($context, $api->authorise($context));
   return;
}

sub dispatch : Auth('none') {
   my ($self, $context, @args) = @_;

   my $api = $context->controllers->{rest}->api;

   $self->_stash_result($context, $api->dispatch($context, @args));
   return;
}

sub refresh : Auth('none') {
   my ($self, $context) = @_;

   my $api = $context->controllers->{rest}->api;

   $self->_stash_result($context, $api->refresh($context));
}

# Private methods
sub _stash_result {
   my ($self, $context, $result) = @_;

   $context->stash(code => $result->[0], json => $result->[1]);
   $context->stash(finalised => TRUE, view => 'json');
   return;
}

1;
