package MCat::Table::Selector::List;

use HTML::StateTable::Constants qw( FALSE SPC TABLE_META TRUE );
use HTML::StateTable::Types     qw( Int );
use MCat::Object::View::List;
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';
with    'HTML::StateTable::Role::Form';

has '+no_count' => default => TRUE;

has '+paging' => default => FALSE;

has 'table_id' => is => 'ro', isa => Int, required => TRUE;

setup_resultset sub {
   return MCat::Object::View::List->new(table => shift);
};

set_table_name 'list_selector';

has_column 'check' =>
   cell_traits => ['Checkbox'],
   label       => SPC,
   options     => { select_one => TRUE },
   value       => 'value';

has_column 'name' =>
   label   => SPC,
   options => { notraits => TRUE },
   width   => '8rem';

use namespace::autoclean -except => TABLE_META;

1;
