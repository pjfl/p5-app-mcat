package MCat::Table::ImportLog::View;

use HTML::StateTable::Constants qw( FALSE TRUE );
use Moo;

extends 'MCat::Table::Object::View';

has '+caption' => default => 'Import Log View';

use namespace::autoclean;

1;
