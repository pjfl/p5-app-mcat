package MCat::Table::List;

use HTML::StateTable::Constants qw( FALSE NUL SPC TABLE_META TRUE );
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';

has '+caption' => default => 'Lists List';

set_table_name 'lists';

setup_resultset sub {
   my $rs = shift->context->model('List');

   return $rs->search({}, { prefetch => 'core_table' });
};

has_column 'name' =>
   link     => sub {
      my $self    = shift;
      my $context = $self->table->context;

      return  $context->uri_for_action('list/view', [$self->result->id]);
   },
   sortable => TRUE,
   title    => 'Sort by name';

has_column 'description' => width => '20rem';

has_column 'table_id' => label => 'Table', value => 'core_table.name';

use namespace::autoclean -except => TABLE_META;

1;
