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

has '+filterable_label' => default => sub {
   return shift->context->request->uri_for('img/filter.svg')->as_string;
};

has '+form_buttons' => default => sub {
   return [{
      action    => 'logfile/clear_cache',
      selection => 'disable_on_select',
      value     => 'Clear Cache',
   }];
};

has '+form_control_location' => default => 'BottomLeft';

has '+name' => default => sub { shift->logfile };

has '+page_control_location' => default => 'TopRight';

has '+title_location' => default => 'inner';

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
   width       => '18ch';

has_column 'status' => filterable => TRUE, width => '10ch';

has_column 'username' => filterable => TRUE, searchable => TRUE,
   width => '14ch';

has_column 'source' => width => '20rem', searchable => TRUE;

has_column 'remainder' => label => 'Line', searchable => TRUE;

use namespace::autoclean -except => TABLE_META;

1;
