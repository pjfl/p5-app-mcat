package MCat::Table::Selector::Field;

use HTML::StateTable::Constants qw( FALSE SPC TABLE_META TRUE );
use HTML::StateTable::Types     qw( Str );
use MCat::Object::View::Class;
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';
with    'HTML::StateTable::Role::Form';

has '+no_count' => default => TRUE;

has '+paging' => default => FALSE;

has 'result_class' => is => 'ro', isa => Str, required => TRUE;

setup_resultset sub {
   return MCat::Object::View::Class->new(table => shift);
};

set_table_name 'field_selector';

has_column 'check' =>
   cell_traits => ['Checkbox'],
   label       => SPC,
   value       => 'value';

has_column 'name' =>
   label   => SPC,
   options => { notraits => TRUE },
   width   => '8rem';

use namespace::autoclean -except => TABLE_META;

1;
