package MCat::Model::API;

use File::DataClass::Functions qw( ensure_class_loaded );
use HTML::Forms::Constants     qw( FALSE EXCEPTION_CLASS TRUE );
use HTML::Forms::Types         qw( HashRef );
use MCat::Util                 qw( clear_redirect );
use Unexpected::Functions      qw( catch_class throw APIMethodFailed
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
      'api/navigation_messages' => 'api/navigation/collect/messages',
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
   catch { $self->error($context, UnknownAPIClass, [$class]) };

   return if $context->stash->{finalised};

   my $handler = $class->new(name => $name);
   my $coderef = $handler->can($method);

   return $self->error($context, UnknownAPIMethod, [$class, $method])
      unless $coderef;

   return if $context->posted && !$self->has_valid_token($context);

   return $self->error($context, UnauthorisedAPICall, [$class, $method])
      unless $self->_allowed($context, $coderef);

   try { $handler->$method($context, @args) }
   catch_class [
      'MCat::Exception' => sub { $self->error($context, $_) },
      '*' => sub { $self->error($context, APIMethodFailed, [$class,$method,$_])}
   ];

   $context->stash( json => (delete($context->stash->{response}) || {}) )
      unless $context->stash('json');

   return if $context->stash->{finalised};

   $context->stash(view => 'json');
   return;
}

sub _allowed {
   my ($self, $context, $coderef) = @_;

   my $attr = MCat::Navigation::Attributes->fetch($coderef) // {};

   return TRUE if $self->is_authorised($context, $attr);

   clear_redirect $context;
   return FALSE;
}

1;
