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
with    'HTML::StateTable::Role::Form';

has 'logfile' => is => 'ro', isa => Str, required => TRUE;

has 'redis' => is => 'ro', isa => class_type('MCat::Redis'), required => TRUE;

has '+form_buttons' => default => sub {
   return [{
      action    => 'logfile/clear_cache',
      selection => 'disable_on_select',
      value     => 'Clear Cache',
   }];
};

has '+form_control_location' => default => 'TopRight';

has '+name' => default => sub { shift->logfile };

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

has_column 'timestamp' =>
   cell_traits => ['DateTime'],
   label       => 'Timestamp',
   searchable  => TRUE,
   sortable    => TRUE,
   width       => '160px';

has_column 'status' => filterable => TRUE, width => '100px';

has_column 'username' => filterable => TRUE, searchable => TRUE;

has_column 'source' => width => '200px', searchable => TRUE;

has_column 'remainder' => label => 'Line', searchable => TRUE;

use namespace::autoclean -except => TABLE_META;

1;
