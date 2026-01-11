package MCat::Table::Filter;

use HTML::StateTable::Constants qw( FALSE NUL SPC TABLE_META TRUE );
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';

has '+caption' => default => 'Filters List';

has '+page_size_control_location' => default => 'BottomLeft';

set_table_name 'filters';

setup_resultset sub {
   my $rs = shift->context->model('Filter');

   return $rs->search({}, { prefetch => 'core_table' });
};

has_column 'name' =>
   link     => sub {
      my $self    = shift;
      my $context = $self->table->context;

      return $context->uri_for_action('filter/view', [$self->result->id]);
   },
   sortable => TRUE,
   title    => 'Sort by name',
   width    => '10rem';

has_column 'description', width => '15rem';

has_column 'table_id', label => 'Table', value => 'core_table.name';

use namespace::autoclean -except => TABLE_META;

1;
