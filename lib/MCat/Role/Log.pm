package MCat::Role::Log;

use Class::Usul::Cmd::Types qw( Logger );
use MCat::Log;
use Moo::Role;

requires qw( config );

has 'log' =>
   is      => 'lazy',
   isa     => Logger,
   default => sub { MCat::Log->new( config => shift->config ) };

use namespace::autoclean;

1;
