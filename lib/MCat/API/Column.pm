package MCat::API::Column;

use MCat::Constants   qw( FALSE TRUE );
use Unexpected::Types qw( ArrayRef Bool CodeRef Dict Enum HashRef
                          NonEmptySimpleStr Optional Str );
use MCat::API::Description;
use Moo;
use MooX::HandlesVia;

my $locations = Enum[qw(body path query)];
my $types     = Enum[qw(array array_of_hash array_of_int bool datetime dbl
                        hash hash/array_of_hash int int/str str )];

has 'constraints' =>
   is          => 'ro',
   isa         => Dict[
      actions => Optional[Dict[ validate => Str ]],
      filters => Optional[HashRef],
      options => Optional[HashRef],
   ],
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

has 'location' => is => 'ro', isa => $locations, default => 'query';

has 'name' => is => 'ro', isa => NonEmptySimpleStr, required => TRUE;

has 'methods' => is => 'ro', isa => HashRef[Bool], default => sub { {} };

has 'type' => is => 'ro', isa => $types, required => TRUE;

sub constraints_display {
   my $self    = shift;
   my $actions = $self->constraints->{actions} or return 'None';

   return 'None' unless $actions->{validate};

   (my $valids = $actions->{validate}) =~ s{ is (\w+) }{$1}gmx;

   return $valids || 'None';
}

use namespace::autoclean;

1;
