package MCat::Table::Cd;

use HTML::StateTable::Constants qw( FALSE TABLE_META TRUE );
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';

set_table_name 'cd';

has_column 'artist_name' =>
   hidden => sub {
      my $table = shift;
      my $context = $table->context;

      return $context->stash('artist') ? TRUE : FALSE;
   },
   label => 'Artist',
   link => sub {
      my $self = shift;
      my $context = $self->table->context;

      return $context->uri_for_action('artist/view', [$self->result->artistid]);
   },
   sortable => TRUE,
   value => 'artist.name';

has_column 'title' =>
   link => sub {
      my $self = shift;
      my $context = $self->table->context;

      return  $context->uri_for_action('cd/view', [$self->result->cdid]);
   },
   sortable => TRUE;

has_column 'year' =>
   cell_traits => ['Date'],
   label => 'Released',
   sortable => TRUE;

use namespace::autoclean -except => TABLE_META;

1;
