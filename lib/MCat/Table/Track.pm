package MCat::Table::Track;

use HTML::StateTable::Constants qw( FALSE TABLE_META TRUE );
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';

set_table_name 'track';

has_column 'trackid' => cell_traits => ['Numeric'],  label => 'Track ID';

has_column 'cd_title' =>
   label    => 'CD Title',
   sortable => TRUE,
   value    => 'cd.title';

has_column 'title' =>
   sortable => TRUE,
   link     => sub {
      my $self    = shift;
      my $context = $self->table->context;

      return  $context->uri_for_action('track/view', [$self->result->trackid]);
   };

use namespace::autoclean -except => TABLE_META;

1;
