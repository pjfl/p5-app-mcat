package MCat::Table::Import;

use HTML::StateTable::Constants qw( FALSE NUL SPC TABLE_META TRUE );
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';

has '+caption' => default => 'Import List';

has '+page_size_control_location' => default => 'BottomLeft';

set_table_name 'import';

setup_resultset sub {
   return shift->context->model('Import');
};

has_column 'id' => cell_traits => ['Numeric'], width => '2rem';

has_column 'name' =>
   link     => sub {
      my $self    = shift;
      my $context = $self->table->context;

      return  $context->uri_for_action('import/view', [$self->result->id]);
   },
   sortable => TRUE,
   title    => 'Sort by name',
   width    => '20rem';

use namespace::autoclean -except => TABLE_META;

1;
