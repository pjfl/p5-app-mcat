package MCat::Table::Logfile::View;

use HTML::StateTable::Constants qw( FALSE NUL SPC TABLE_META TRUE );
use HTML::StateTable::Types     qw( Str );
use MCat::Logfile::View;
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';
with    'HTML::StateTable::Role::Filterable';
with    'HTML::StateTable::Role::Searchable';

has 'logfile' => is => 'ro', isa => Str, required => TRUE;

setup_resultset sub {
   my $self   = shift;
   my $config = $self->context->config;

   return MCat::Logfile::View->new(
      base         => $config->logfile->parent,
      logfile      => $self->logfile,
      cache_config => $config->redis,
   );
};

set_table_name 'logfile_view';

has_column 'timestamp' =>
   cell_traits => ['DateTime'],
   label       => 'Timestamp',
   sortable    => TRUE,
   width       => '160px';

has_column 'status' => filterable => TRUE, width => '100px';

has_column 'source' => width => '300px';

has_column 'remainder' => label => 'Line', searchable => TRUE;

use namespace::autoclean -except => TABLE_META;

1;
