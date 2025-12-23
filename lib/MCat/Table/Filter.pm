package MCat::Table::Filter;

use HTML::StateTable::Constants qw( FALSE NUL SPC TABLE_META TRUE );
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';

has '+caption' => default => 'Filters List';

has '+page_size_control_location' => default => 'BottomLeft';

set_table_name 'filters';

setup_resultset sub {
   return shift->context->model('Filter');
};

has_column 'name' =>
   link     => sub {
      my $self    = shift;
      my $context = $self->table->context;

      return  $context->uri_for_action('filter/view', [$self->result->id]);
   },
   sortable => TRUE,
   title    => 'Sort by name',
   width    => '10rem';

has_column 'description',
   width => '15rem';

use namespace::autoclean -except => TABLE_META;

1;
