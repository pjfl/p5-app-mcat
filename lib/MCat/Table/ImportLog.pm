package MCat::Table::ImportLog;

use HTML::StateTable::Constants qw( FALSE NUL SPC TABLE_META TRUE );
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';
with    'HTML::StateTable::Role::Form';
with    'HTML::StateTable::Role::Searchable';
with    'HTML::StateTable::Role::Configurable';
with    'HTML::StateTable::Role::Reorderable';
with    'HTML::StateTable::Role::Filterable';

has '+configurable_action' => default => 'api/table_preference';

has '+icons' => default => sub { shift->context->icons_uri->as_string };

has '+page_size' => default => 10;

has '+page_size_control_location' => default => 'BottomRight';

has 'import' => is => 'ro';

before 'BUILD' => sub {
   my $self = shift;

   if ($self->import) {
      $self->configurable(FALSE);
      $self->searchable(FALSE);
   }

   return;
};

set_table_name 'import_log';

setup_resultset sub {
   my $self  = shift;
   my $rs    = $self->context->model('ImportLog');
   my $where = {};

   $where = { import_id => $self->import->id } if $self->import;

   return $rs->search($where, { prefetch => ['import', 'owner']});
};

has_column 'guid' =>
   label      => 'Log ID',
   link       => sub {
      my $self    = shift;
      my $context = $self->table->context;
      my $logid   = $self->result->import_log_id;

      return $context->uri_for_action('importlog/view', [$logid]);
   },
   searchable => TRUE,
   sortable   => TRUE,
   title      => 'Sort by GUID';

has_column 'source' =>
   filterable => TRUE,
   label      => 'Source File',
   searchable => TRUE,
   sortable   => TRUE,
   title      => 'Sort by source file';

has_column 'import_id' =>
   hidden     => sub { shift->import },
   label      => 'Imported Into',
   searchable => TRUE,
   sortable   => TRUE,
   title      => 'Sort by import destination',
   value      => 'import.core_table.name';

has_column 'owner_user_id' =>
   hidden     => sub { shift->import },
   label      => 'Owner',
   searchable => TRUE,
   sortable   => TRUE,
   title      => 'Sort by user',
   value      => 'owner.name';

has_column 'started' =>
   cell_traits => ['DateTime'],
   sortable    => TRUE,
   title       => 'Sort by start time';

has_column 'finished' =>
   cell_traits => ['DateTime'],
   hidden      => sub { shift->import },
   sortable    => TRUE,
   title       => 'Sort by finish time';

has_column 'inserted' =>
   cell_traits => ['Numeric'],
   hidden      => sub { shift->import };

has_column 'updated' =>
   cell_traits => ['Numeric'],
   hidden      => sub { shift->import };

has_column 'count' =>
   cell_traits => ['Numeric'],
   hidden      => sub { !shift->import };

use namespace::autoclean -except => TABLE_META;

1;



1;
