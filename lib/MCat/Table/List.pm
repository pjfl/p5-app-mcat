package MCat::Table::List;

use HTML::StateTable::Constants qw( FALSE NUL SPC TABLE_META TRUE );
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';

has '+caption' => default => 'List Lists';

has 'filter' => is => 'ro', predicate => TRUE;

has 'table' => is => 'ro', predicate => TRUE;

set_table_name 'lists';

setup_resultset sub {
   my $self  = shift;
   my $rs    = $self->context->model('List');
   my $where = {};

   $where = { filter_id => $self->filter->id } if $self->has_filter;

   $where = { table_id => $self->table->id } if $self->has_table;

   return $rs->search($where, { prefetch => 'core_table' });
};

has_column 'name' =>
   link     => sub {
      my $self    = shift;
      my $context = $self->table->context;

      return  $context->uri_for_action('list/view', [$self->result->id]);
   },
   sortable => TRUE,
   title    => 'Sort by name';

has_column 'description' => width => '12rem';

has_column 'table_id' =>
   hidden => sub { shift->has_filter },
   label  => 'Table',
   value  => 'core_table.name';

has_column 'updated' => cell_traits => ['DateTime'];

use namespace::autoclean -except => TABLE_META;

1;
