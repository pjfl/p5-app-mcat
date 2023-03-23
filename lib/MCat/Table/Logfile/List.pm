package MCat::Table::Logfile::List;

use File::DataClass::Types      qw( Directory );
use HTML::StateTable::Constants qw( FALSE NUL SPC TABLE_META TRUE );
use HTML::StateTable::ResultSet::Logfile::List;
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';

has '+paging' => default => FALSE;

setup_resultset sub {
   my $self = shift;

   return HTML::StateTable::ResultSet::Logfile::List->new(
      base         => $self->context->config->logfile->parent,
      result_class => 'MCat::Logfile::List::Result',
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
   label       => 'Size',
   sortable    => TRUE;

use namespace::autoclean -except => TABLE_META;

1;
