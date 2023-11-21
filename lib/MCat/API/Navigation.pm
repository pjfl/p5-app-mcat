package MCat::API::Navigation;

use HTML::Forms::Constants qw( FALSE TRUE );
use HTML::Forms::Types     qw( Str );
use JSON::MaybeXS          qw( );
use Type::Utils            qw( class_type );
use Moo;
use MCat::Navigation::Attributes; # Will do namespace cleaning

has 'name' => is => 'ro', isa => Str; # collect

has '_json' => is => 'ro', isa => class_type(JSON::MaybeXS::JSON),
   default => sub { JSON::MaybeXS->new( convert_blessed => TRUE ) };

sub messages : Auth('none') {
   my ($self, $context, @args) = @_;

   if ($self->name eq 'collect') {
      my $messages
         = $context->session->collect_status_messages($context->request);

      $context->stash( body => $self->_json->encode($messages) );
   }

   return;
}

1;
