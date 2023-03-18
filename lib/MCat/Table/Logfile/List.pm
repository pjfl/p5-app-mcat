package MCat::Table::Logfile::List;

use File::DataClass::Types      qw( Directory );
use HTML::StateTable::Constants qw( FALSE NUL SPC TABLE_META TRUE );
use MCat::Logfile::List;
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';

setup_resultset sub {
   my $self = shift;
   my $base = $self->context->config->logfile->parent;

   return MCat::Logfile::List->new(base => $base, table => $self);
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
