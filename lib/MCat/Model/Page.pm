package MCat::Model::Page;

use HTML::Forms::Constants qw( EXCEPTION_CLASS );
use HTTP::Status           qw( HTTP_NOT_FOUND );
use Unexpected::Functions  qw( PageNotFound );
use Web::Simple;

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'page';

sub not_found {
   my ($self, $context) = @_;

   my @options = ( [$context->request->path], rv => HTTP_NOT_FOUND );

   return $self->error($context, PageNotFound, @options);
}

use namespace::autoclean;

1;
