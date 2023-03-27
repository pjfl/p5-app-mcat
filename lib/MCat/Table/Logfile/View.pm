package MCat::Table::Logfile::View;

use HTML::StateTable::Constants qw( FALSE NUL SPC TABLE_META TRUE );
use HTML::StateTable::Types     qw( Str );
use Type::Utils                 qw( class_type );
use HTML::StateTable::ResultSet::Logfile::View;
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';
with    'HTML::StateTable::Role::Filterable';
with    'HTML::StateTable::Role::Searchable';

has 'logfile' => is => 'ro', isa => Str, required => TRUE;

has 'redis' => is => 'ro', isa => class_type('MCat::Redis'), required => TRUE;

setup_resultset sub {
   my $self   = shift;
   my $config = $self->context->config;

   return HTML::StateTable::ResultSet::Logfile::View->new(
      base         => $config->logfile->parent,
      logfile      => $self->logfile,
      redis        => $self->redis,
      result_class => 'MCat::Logfile::View::Result',
      table        => $self,
   );
};

set_table_name 'logfile_view';

has_column 'timestamp' =>
   cell_traits => ['DateTime'],
   label       => 'Timestamp',
   searchable  => TRUE,
   sortable    => TRUE,
   width       => '160px';

has_column 'status' => filterable => TRUE, width => '100px';

has_column 'source' => width => '300px', searchable => TRUE;

has_column 'remainder' => label => 'Line', searchable => TRUE;

use namespace::autoclean -except => TABLE_META;

1;
