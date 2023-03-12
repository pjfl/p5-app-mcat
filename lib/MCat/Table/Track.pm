package MCat::Table::Track;

use HTML::StateTable::Constants qw( TABLE_META );
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';

set_table_name 'track';

has_column 'trackid' => label => 'Track ID', cell_traits => ['Numeric'];

has_column 'cdid' => label => 'CD ID', cell_traits => ['Numeric'];

has_column 'title' => link => sub {
   my $self    = shift;
   my $context = $self->table->context;

   return  $context->uri_for_action('track/view', [$self->result->trackid]);
};

use namespace::autoclean -except => TABLE_META;

1;
