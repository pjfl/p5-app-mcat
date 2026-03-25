package MCat::API::Meta;

use Unexpected::Types qw( ArrayRef );
use Moo;
use MooX::HandlesVia;

has 'column_list' =>
   is            => 'rw',
   isa           => ArrayRef,
   default       => sub { [] },
   handles_via   => 'Array',
   handles       => {
      add_to_column_list => 'push',
      clear_column_list  => 'clear',
      has_column_list    => 'count',
   };

has 'method_list' =>
   is            => 'rw',
   isa           => ArrayRef,
   default       => sub { [] },
   handles_via   => 'Array',
   handles       => {
      add_to_method_list => 'push',
      clear_method_list  => 'clear',
      has_method_list    => 'count',
   };

use namespace::autoclean;

1;
