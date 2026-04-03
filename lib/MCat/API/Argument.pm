package MCat::API::Argument;

use MCat::Constants qw( FALSE TRUE );
use Unexpected::Types qw( Enum HashRef NonEmptySimpleStr Str );
use MCat::API::Description;
use Moo;

my $locations = Enum[qw(body path query)];
my $types     = Enum[qw(array array_of_hash array_of_int bool datetime dbl
                        hash hash/array_of_hash int int/str str )];

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

has 'location' => is => 'ro', isa => $locations, default => 'query';

has 'name' => is => 'ro', isa => NonEmptySimpleStr, required => TRUE;

has 'fields' => is => 'ro', isa => Str, predicate => TRUE;

has 'type' => is => 'ro', isa => $types, required => TRUE;

use namespace::autoclean;

1;
