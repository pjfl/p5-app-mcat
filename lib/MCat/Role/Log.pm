package MCat::Role::Log;

use Class::Usul::Cmd::Types qw( Logger );
use MCat::Log;
use Moo::Role;

requires qw( config );

has 'log' =>
   is      => 'lazy',
   isa     => Logger,
   default => sub { MCat::Log->new(builder => shift) };

use namespace::autoclean;

1;
