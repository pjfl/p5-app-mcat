package MCat::Table::Logfile;

use HTML::StateTable::Constants qw( FALSE NUL SPC TABLE_META TRUE );
use File::DataClass::Types      qw( Directory );
use Format::Human::Bytes;
use HTML::StateTable::ResultSet::File::List;
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';
with    'HTML::StateTable::Role::Form';

has '+caption' => default => 'Logfile List';

has '+icons' => default => sub {
   return shift->context->request->uri_for('img/icons.svg')->as_string;
};

has '+paging' => default => FALSE;

has 'format_number' => is => 'ro', default => sub { Format::Human::Bytes->new };

setup_resultset sub {
   my $self = shift;

   return HTML::StateTable::ResultSet::File::List->new(
      directory    => $self->context->config->logfile->parent,
      result_class => 'MCat::Logfile::Result::List',
      table        => $self
   );
};

set_table_name 'logfile_list';

has_column 'name' =>
   label => 'Name',
   link  => sub {
      my $self    = shift;
      my $context = $self->table->context;
      my $arg     = $self->result->uri_arg;

      return $context->uri_for_action('logfile/view', [$arg]);
   },
   sortable => TRUE;

has_column 'modified' =>
   cell_traits => ['DateTime'],
   label       => 'Modified',
   sortable    => TRUE;

has_column 'size' =>
   cell_traits => ['Numeric'],
   value       => sub {
      my $cell = shift;

      return $cell->table->format_number->base2($cell->result->size);
   };

use namespace::autoclean -except => TABLE_META;

1;
