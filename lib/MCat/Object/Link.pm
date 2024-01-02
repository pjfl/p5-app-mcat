package MCat::Object::Link;

use HTML::StateTable::Constants qw( FALSE TRUE );
use Moo;

has 'link' => is => 'ro', required => TRUE;

has 'value' => is => 'ro', required => TRUE;

sub render {
   my $self = shift;

   return { link => $self->link, value => $self->value };
}

use namespace::autoclean;

1;
