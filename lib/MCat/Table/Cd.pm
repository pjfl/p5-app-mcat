package MCat::Table::Cd;

use HTML::StateTable::Constants qw( FALSE TABLE_META TRUE );
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';

set_table_name 'cd';

has_column 'cdid' => cell_traits => ['Numeric'], label => 'ID';

has_column 'title' =>
   sortable => TRUE,
   link     => sub {
      my $self    = shift;
      my $context = $self->table->context;

      return  $context->uri_for_action('cd/view', [$self->result->cdid]);
   };

has_column 'year' =>
   cell_traits => ['Date'],
   label       => 'Released',
   sortable    => TRUE;

use namespace::autoclean -except => TABLE_META;

1;
