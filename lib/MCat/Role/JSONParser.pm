package MCat::Role::JSONParser;

use Class::Usul::Cmd::Constants qw( FALSE TRUE );
use Type::Utils                 qw( class_type );
use JSON::MaybeXS               qw( );
use Moo::Role;

# Private attributes
has 'json_parser' =>
   is      => 'lazy',
   isa     => class_type(JSON::MaybeXS::JSON),
   default => sub { JSON::MaybeXS->new( convert_blessed => TRUE ) };

use namespace::autoclean;

1;
