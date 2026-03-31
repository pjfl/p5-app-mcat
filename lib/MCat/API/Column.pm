package MCat::API::Column;

use MCat::Constants   qw( FALSE TRUE );
use Unexpected::Types qw( ArrayRef Bool CodeRef HashRef Str );
use MCat::API::Description;
use Moo;
use MooX::HandlesVia;

has 'constraints' =>
   is          => 'ro',
   isa         => HashRef,
   handles_via => 'Hash',
   handles     => { has_constraints => 'count' },
   default     => sub { {} };

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

has 'getter' => is => 'ro', isa => CodeRef, predicate => TRUE;

has 'location' => is => 'ro', isa => Str, default => 'query';

has 'name' => is => 'ro', isa => Str, required => TRUE;

has 'methods' => is => 'ro', isa => HashRef[Bool], default => sub { {} };

has 'type' => is => 'ro', isa => Str, required => TRUE;

use namespace::autoclean;

1;
