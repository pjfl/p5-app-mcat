package MCat::Role::FileMeta;

use MCat::Constants        qw( EXCEPTION_CLASS FALSE TRUE );
use File::DataClass::Types qw( Directory Path Str );
use Type::Utils            qw( class_type );
use MCat::File;
use Moo::Role;

has 'file' =>
   is      => 'lazy',
   isa     => class_type('MCat::File'),
   default => sub {
      my $self = shift;
      my $args = { home => $self->file_home, share => $self->file_share };

      return MCat::File->new($args);
   };

has 'file_extensions' => is => 'ro', isa => Str, default => 'csv|txt';

has 'file_home' => is => 'ro', isa => Directory, required => TRUE;

has 'file_share' => is => 'ro', isa => Path, required => TRUE;

use namespace::autoclean;

1;
