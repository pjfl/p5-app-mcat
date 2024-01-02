package MCat::Table::Cd;

use HTML::StateTable::Constants qw( FALSE TABLE_META TRUE );
use HTML::StateTable::Types     qw( Int );
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';

has '+caption' => default => 'CD List';

has 'artistid' => is => 'ro', isa => Int, predicate => 'has_artistid';

has 'list_id' => is => 'ro', isa => Int, predicate => 'has_list_id';

after 'BUILD' => sub {
   my $self = shift;

   $self->paging(FALSE) if $self->has_artistid;
   return;
};

set_table_name 'cd';

setup_resultset sub {
   my $self = shift;
   my $rs   = $self->context->model('Cd');

   $rs = $rs->search({ 'me.artistid' => $self->artistid })
      if $self->has_artistid;

   return $rs unless $self->has_list_id;

   my $list_rs = $self->context->model('ListCd');
   my $where   = { list_id => $self->list_id };

   $list_rs = $list_rs->search($where)->get_column('cdid');

   return $rs->search({ 'me.cdid' => { -in => $list_rs->as_query } });
};

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
