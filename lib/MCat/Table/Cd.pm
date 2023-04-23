package MCat::Table::Cd;

use HTML::StateTable::Constants qw( FALSE TABLE_META TRUE );
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';

has '+caption' => default => 'CD List';

after 'BUILD' => sub {
   my $self = shift;

   $self->paging(FALSE) if $self->context->stash('artist');
   return;
};

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
   title => 'Sort by artist',
   value => 'artist.name';

has_column 'title' =>
   label => 'CD Title',
   link  => sub {
      my $self = shift;
      my $context = $self->table->context;

      return  $context->uri_for_action('cd/view', [$self->result->cdid]);
   },
   sortable => TRUE,
   title    => 'Sort by title';

has_column 'year' =>
   cell_traits => ['Date'],
   label       => 'Released',
   sortable    => TRUE,
   title       => 'Sort by year';

use namespace::autoclean -except => TABLE_META;

1;
