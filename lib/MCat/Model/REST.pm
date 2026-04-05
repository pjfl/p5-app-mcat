package MCat::Model::REST;

use MCat::Constants qw( EXCEPTION_CLASS FALSE TRUE );
use Moo;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'rest';

sub base : Auth('view') {
   my ($self, $context) = @_;

   $context->stash('nav')->finalise;

   return;
}

sub documentation : Auth('view') Nav('API') {
   my ($self, $context, $entity_name) = @_;

   my $api    = $context->controllers->{rest}->api;
   my $prefix = $context->request->uri_for($api->route_prefix);

   $context->stash(entity_list  => $api->entity_list);
   $context->stash(entity       => $api->get_entity($entity_name));
   $context->stash(route_prefix => $prefix);
   return;
}

sub authorise : Auth('none') {
   my ($self, $context) = @_;

   my $api = $context->controllers->{rest}->api;

   $self->_stash_result($context, $api->authorise($context));
   return;
}

sub access_token : Auth('none') {
   my ($self, $context) = @_;

   my $api = $context->controllers->{rest}->api;

   $self->_stash_result($context, $api->access_token($context));
   return;
}

sub refresh : Auth('none') {
   my ($self, $context) = @_;

   my $api = $context->controllers->{rest}->api;

   $self->_stash_result($context, $api->refresh($context));
}

sub dispatch : Auth('none') {
   my ($self, $context, @args) = @_;

   my $api = $context->controllers->{rest}->api;

   $self->_stash_result($context, $api->dispatch($context, @args));
   return;
}

# Private methods
sub _stash_result {
   my ($self, $context, $result) = @_;

   $context->stash(code => $result->[0], json => $result->[1]);
   $context->stash(finalised => TRUE, view => 'json');
   return;
}

1;
