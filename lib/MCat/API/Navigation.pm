package MCat::API::Navigation;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE TRUE );
use HTML::Forms::Types     qw( Str );
use Unexpected::Functions  qw( throw );
use Moo;
use MCat::Navigation::Attributes; # Will do namespace cleaning

has 'name' => is => 'ro', isa => Str; # collect

sub messages : Auth('none') {
   my ($self, $context, @args) = @_;

   if ($self->name eq 'collect') {
      my $messages
         = $context->session->collect_status_messages($context->request);

      $context->stash( json => $messages );
   }
   else { throw 'Object [_1] unknown api attribute name', [$self->name] }

   return;
}

1;
