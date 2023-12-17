package MCat::Table::List;

use HTML::StateTable::Constants qw( FALSE NUL SPC TABLE_META TRUE );
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';

has '+caption' => default => 'Lists List';

has '+page_size_control_location' => default => 'BottomLeft';

set_table_name 'lists';

setup_resultset sub {
   return shift->context->model('List');
};

has_column 'id' => cell_traits => ['Numeric'], width => '2rem';

has_column 'name' =>
   link     => sub {
      my $self    = shift;
      my $context = $self->table->context;

      return  $context->uri_for_action('list/view', [$self->result->id]);
   },
   sortable => TRUE,
   title    => 'Sort by name',
   width    => '20rem';

use namespace::autoclean -except => TABLE_META;

1;
