package MCat::API::Navigation;

use HTML::Forms::Constants qw( FALSE TRUE );
use HTML::Forms::Types     qw( Str );
use JSON::MaybeXS          qw( );
use Type::Utils            qw( class_type );
use Moo;

has 'name' => is => 'ro', isa => Str; # collect

has '_json' => is => 'ro', isa => class_type(JSON::MaybeXS::JSON),
   default => sub { JSON::MaybeXS->new( convert_blessed => TRUE ) };

sub messages {
   my ($self, $context, @args) = @_;

   my $messages = $context->session->collect_status_messages($context->request);

   $context->stash( body => $self->_json->encode($messages) );
   return;
}

use namespace::autoclean;

1;
