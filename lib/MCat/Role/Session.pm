package MCat::Role::Session;

use Type::Utils qw( class_type );
use MCat::Session;
use Moo::Role;

requires qw( config );

has 'session' =>
   is      => 'lazy',
   isa     => class_type('MCat::Session'),
   default => sub { MCat::Session->new(config => shift->config) };

use namespace::autoclean;

1;
