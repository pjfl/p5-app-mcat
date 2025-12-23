package MCat::Table::Track;

use HTML::StateTable::Constants qw( FALSE TABLE_META TRUE );
use HTML::StateTable::Types     qw( Int );
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';

has '+caption' => default => 'Track List';

has '+page_control_location' => default => 'TopLeft';

has '+page_size_control_location' => default => 'BottomLeft';

has 'cdid' => is => 'ro', isa => Int, predicate => 'has_cdid';

has 'list_id' => is => 'ro', isa => Int, predicate => 'has_list_id';

after 'BUILD' => sub {
   my $self = shift;

   $self->paging(FALSE) if $self->has_cdid;

   if ($self->has_list_id) {
      my $list_rs   = $self->context->model('List');
      my $list_name = $list_rs->find($self->list_id)->name;

      $self->caption("Tracks in List ${list_name}");
   }

   return;
};

set_table_name 'track';

setup_resultset sub {
   my $self    = shift;
   my $rs      = $self->context->model('Track');
   my $options = { prefetch => { 'cd' => 'artist' } };

   $rs = $rs->search({}, $options);
   $rs = $rs->search({ 'me.cdid' => $self->cdid }) if $self->has_cdid;

   return $rs unless $self->has_list_id;

   my $join_rs = $self->context->model('ListTrack');
   my $where   = { list_id => $self->list_id };

   $join_rs = $join_rs->search($where)->get_column('trackid');

   return $rs->search({ 'me.trackid' => { -in => $join_rs->as_query } });
};

has_column 'title' =>
   label    => 'Track Title',
   link     => sub {
      my $self    = shift;
      my $context = $self->table->context;

      return  $context->uri_for_action('track/view', [$self->result->trackid]);
   },
   sortable => TRUE,
   title    => 'Sort by track title';

has_column 'cd_title' =>
   hidden   => sub { shift->context->stash('cd') ? TRUE : FALSE },
   label    => 'CD Title',
   link => sub {
      my $self    = shift;
      my $context = $self->table->context;

      return $context->uri_for_action('cd/view', [$self->result->cdid]);
   },
   sortable => TRUE,
   title    => 'Sort by CD title',
   value    => 'cd.title';

has_column 'cd_artist' =>
   hidden   => sub { shift->context->stash('cd') ? TRUE : FALSE },
   label    => 'Artist',
   link => sub {
      my $self    = shift;
      my $context = $self->table->context;
      my $args    = [$self->result->cd->artistid];

      return $context->uri_for_action('artist/view', $args);
   },
   sortable => TRUE,
   title    => 'Sort by Artist',
   value    => 'cd.artist.name';

has_column 'cd_year' =>
   cell_traits => ['Date'],
   hidden      => sub { shift->context->stash('cd') ? TRUE : FALSE },
   label       => 'Released',
   sortable    => TRUE,
   title       => 'Sort by release date',
   value       => 'cd.year';

use namespace::autoclean -except => TABLE_META;

1;
