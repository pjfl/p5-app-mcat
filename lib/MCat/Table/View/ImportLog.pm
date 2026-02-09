package MCat::Table::View::ImportLog;

use HTML::StateTable::Constants qw( FALSE TRUE );
use Moo;

extends 'MCat::Table::View::Object';

has '+caption' => default => 'View Import Log';

use namespace::autoclean;

1;
