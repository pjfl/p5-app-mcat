package MCat::Table::Track;

use HTML::StateTable::Constants qw( FALSE TABLE_META TRUE );
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';

has '+caption' => default => 'Track List';

after 'BUILD' => sub {
   my $self = shift;

   $self->paging(FALSE) if $self->context->stash('cd');
   return;
};

set_table_name 'track';

has_column 'cd_title' =>
   hidden   => sub {
      my $table   = shift;
      my $context = $table->context;

      return $context->stash('cd') ? TRUE : FALSE;
   },
   label    => 'CD Title',
   link => sub {
      my $self = shift;
      my $context = $self->table->context;

      return $context->uri_for_action('cd/view', [$self->result->cdid]);
   },
   sortable => TRUE,
   title    => 'Sort by title',
   value    => 'cd.title';

has_column 'title' =>
   label    => 'Track Title',
   link     => sub {
      my $self    = shift;
      my $context = $self->table->context;

      return  $context->uri_for_action('track/view', [$self->result->trackid]);
   },
   sortable => TRUE,
   title    => 'Sort by title';

use namespace::autoclean -except => TABLE_META;

1;
