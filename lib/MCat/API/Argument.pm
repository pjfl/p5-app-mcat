package MCat::API::Argument;

use MCat::Constants qw( FALSE TRUE );
use Unexpected::Types qw( HashRef Str );
use MCat::API::Description;
use Moo;

has 'description' =>
   is        => 'lazy',
   isa       => Str,
   init_arg  => undef,
   predicate => TRUE,
   default   => sub {
      my $self = shift;
      my $args = { text => $self->_description, type => $self->type };
      my $desc = MCat::API::Description->new($args);

      return "${desc}";
   };

has '_description' =>
   is       => 'ro',
   isa      => Str,
   init_arg => 'description',
   default  => 'Undocumented';

has 'location' => is => 'ro', isa => Str, default => 'query';

has 'name' => is => 'ro', isa => Str, required => TRUE;

has 'fields' => is => 'ro', isa => Str, predicate => TRUE;

has 'type' => is => 'ro', isa => Str, required => TRUE;

use namespace::autoclean;

1;
