package MCat::Model::API;

use HTML::Forms::Constants qw( FALSE EXCEPTION_CLASS TRUE );
use Unexpected::Types      qw( HashRef );
use Class::Usul::Cmd::Util qw( ensure_class_loaded );
use Unexpected::Functions  qw( catch_class throw APIMethodFailed
                               UnauthorisedAPICall UnknownAPIClass
                               UnknownAPIMethod UnknownView );
use Try::Tiny;
use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'api';

has 'routes' => is => 'ro', isa => HashRef, default => sub {
   return {
      'api/form_validate_field' => 'api/form/*/field/*/validate',
      'api/navigation_messages' => 'api/navigation/collect/messages',
      'api/object_fetch'        => 'api/object/*/fetch',
      'api/object_get'          => 'api/object/*/get',
      'api/table_action'        => 'api/table/*/action',
      'api/table_preference'    => 'api/table/*/preference',
   };
};

sub dispatch : Auth('none') {
   my ($self, $context, @args) = @_;

   throw UnknownView, ['json'] unless exists $context->views->{'json'};

   my ($ns, $name, $method) = splice @args, 0, 3;
   my $class = ('+' eq substr $ns, 0, 1)
      ? substr $ns, 1 : 'MCat::API::' . ucfirst lc $ns;

   try   { ensure_class_loaded($class) }
   catch { $self->error($context, UnknownAPIClass, [$class, $_]) };

   return if $context->stash->{finalised};

   my $args    = { config => $self->config, log => $self->log, name => $name };
   my $handler = $class->new($args);
   my $action  = $handler->can($method);

   return $self->error($context, UnknownAPIMethod, [$class, $method])
      unless $action;

   return $self->error($context, UnauthorisedAPICall, [$class, $method])
      unless $self->_api_allowed($context, $action);

   return if $context->posted && !$self->verify_form_post($context);

   try { $handler->$method($context, @args) }
   catch_class [
      'MCat::Exception' => sub { $self->error($context, $_) },
      '*' => sub { $self->error($context, APIMethodFailed, [$class,$method,$_])}
   ];

   $context->stash(json => (delete($context->stash->{response}) || {}))
      unless $context->stash('json');

   return if $context->stash->{finalised};

   $context->stash(view => 'json') unless $context->stash->{view};
   return;
}

sub _api_allowed {
   my ($self, $context, $action) = @_;

   return TRUE if $self->is_authorised($context, $action);

   $context->clear_redirect;

   return FALSE;
}

1;
