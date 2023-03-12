package MCat::Model::API;

use File::DataClass::Functions qw( ensure_class_loaded );
use HTML::Forms::Constants     qw( EXCEPTION_CLASS );
use MCat::Util                 qw( redirect register_action_paths );
use Unexpected::Functions      qw( catch_class throw APIMethodFailed
                                   UnknownAPIClass UnknownAPIMethod );
use Try::Tiny;
use Web::Simple;

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'api';

register_action_paths 'api', {
   response         => 'api/**',
   table_action     => 'api/table/*/action',
   table_preference => 'api/table/*/preference',
};

sub response {
   my ($self, $context, @args) = @_;

   throw 'No [_1] view', ['json'] unless exists $context->views->{'json'};

   my ($ns, $name, $method) = splice @args, 0, 3;
   my $class = ('+' eq substr $ns, 0, 1)
      ? substr $ns, 1 : 'MCat::API::' . ucfirst lc $ns;

   try   { ensure_class_loaded($class) }
   catch { $self->error($context, UnknownAPIClass, [$class]) };

   return if $context->stash->{finalised};

   my $handler = $class->new(form => $self->form, name => $name);

   return $self->error($context, UnknownAPIMethod, [$class, $method])
      unless $handler->can($method);

   return if $context->posted && !$self->has_valid_token($context);

   try { $handler->$method($context, @args) }
   catch_class [
      'MCat::Exception' => sub { $self->error($context, $_) },
      '*' => sub {
         $self->error($context, APIMethodFailed, [$class, $method, $_])
      }
   ];

   $context->stash( json => delete($context->stash->{response}) || {} )
      unless $context->stash('json');

   return if $context->stash->{finalised};

   $context->stash(view => 'json');
   return;
}

use namespace::autoclean;

1;
