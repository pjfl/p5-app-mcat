package MCat::Role::CSVParser;

use MCat::Constants qw( FALSE TRUE );
use Type::Utils     qw( class_type );
use Text::CSV_XS;
use Moo::Role;

has 'csv_parser' =>
   is      => 'lazy',
   isa     => class_type('Text::CSV_XS'),
   default => sub {
      return Text::CSV_XS->new({ always_quote => TRUE, binary => TRUE });
   };

use namespace::autoclean;

1;

