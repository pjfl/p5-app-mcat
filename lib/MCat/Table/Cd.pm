package MCat::Table::Cd;

use HTML::StateTable::Constants qw( TABLE_META );
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';

set_table_name 'cd';

has_column 'cdid' => label => 'ID', cell_traits => ['Numeric'];

has_column 'title' => link => sub {
   my $self    = shift;
   my $context = $self->table->context;

   return  $context->uri_for_action('cd/view', [$self->result->cdid]);
};

has_column 'year' => label => 'Released', cell_traits => ['Date'];

use namespace::autoclean -except => TABLE_META;

1;
