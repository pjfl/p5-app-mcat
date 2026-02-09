package MCat::Table::Table;

use HTML::StateTable::Constants qw( FALSE NUL SPC TABLE_META TRUE );
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';

has '+caption' => default => 'List Tables';

has '+page_size_control_location' => default => 'BottomLeft';

set_table_name 'tables';

setup_resultset sub {
   return shift->context->model('Table');
};

has_column 'name' =>
   link     => sub {
      my $self    = shift;
      my $context = $self->table->context;

      return  $context->uri_for_action('table/view', [$self->result->id]);
   },
   sortable => TRUE,
   title    => 'Sort by name',
   width    => '20rem';

has_column 'relation';

use namespace::autoclean -except => TABLE_META;

1;
