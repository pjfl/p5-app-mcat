package MCat::API::Method;

use MCat::Constants   qw( FALSE TRUE );
use HTTP::Status      qw( HTTP_OK );
use Unexpected::Types qw( ArrayRef HashRef Int Maybe Object Str );
use Type::Utils       qw( class_type );
use MCat::API::Argument;
use MCat::API::Description;
use Moo;

has 'access' => is => 'ro', isa => Str, required => TRUE;

has 'action' => is => 'ro', isa => Str, required => TRUE;

has 'additionally' => is => 'ro', isa => HashRef, default => sub { {} };

has 'description' =>
   is        => 'lazy',
   isa       => Str,
   init_arg  => undef,
   predicate => TRUE,
   default   => sub {
      my $self = shift;
      my $desc = MCat::API::Description->new({ text => $self->_description });

      return "${desc}";
   };

has '_description' =>
   is       => 'ro',
   isa      => Str,
   init_arg => 'description',
   default  => 'Undocumented';

has 'examples' => is => 'ro', isa => ArrayRef[HashRef], default => sub { [] };

has 'in_args' =>
   is       => 'lazy',
   isa      => ArrayRef[class_type('MCat::API::Argument')],
   init_arg => undef,
   default  => sub {
      my $self = shift;

      return [ map { MCat::API::Argument->new($_) } @{$self->_in_args} ];
   };

has '_in_args' =>
   is       => 'ro',
   isa      => ArrayRef[HashRef],
   init_arg => 'in_args',
   default  => sub { [] };

has 'method' => is => 'ro', isa => Str, default => 'GET';

has 'name' => is => 'ro', isa => Str, required => TRUE;

has 'out_arg' =>
   is       => 'lazy',
   isa      => Maybe[class_type('MCat::API::Argument')],
   init_arg => undef,
   default  => sub {
      my $arg = shift->_out_arg or return;

      return MCat::API::Argument->new($arg);
   };

has '_out_arg' =>
   is       => 'ro',
   isa      => Maybe[HashRef],
   init_arg => 'out_arg';

has 'route'  => is => 'ro', isa => Str, required => TRUE;

has 'success_code' => is => 'ro', isa => Int, default => HTTP_OK;

sub BUILD {
   my $self = shift;

   $self->in_args;
   $self->out_arg;
   return;
}

sub has_in_args {
   my ($self, $location) = @_;

   for my $arg (@{$self->in_args}) {
      return TRUE if $arg->location eq $location;
   }

   return FALSE;
}

sub route_display {
   my $self = shift;

   (my $route = $self->route) =~ s{ \{ (\w+) : [^\}]* \} }{:$1}gmx;

   return $route;
}

sub route_match {
   my $self = shift;

   (my $route = $self->route) =~ s{ \{[^\}]+\} }{\*}gmx;

   return $route;
}

use namespace::autoclean;

1;
