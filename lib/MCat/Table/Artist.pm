package MCat::Table::Artist;

use HTML::StateTable::Constants qw( FALSE NUL SPC TABLE_META TRUE );
use HTML::StateTable::Types     qw( Int Str );
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable'; # Buddhist table - One with everything
with    'HTML::StateTable::Role::Form';
with    'HTML::StateTable::Role::Active';
with    'HTML::StateTable::Role::Configurable';
with    'HTML::StateTable::Role::Searchable';
with    'HTML::StateTable::Role::Downloadable';
with    'HTML::StateTable::Role::CheckAll';
with    'HTML::StateTable::Role::HighlightRow';
with    'HTML::StateTable::Role::ForceRowLimit';
with    'HTML::StateTable::Role::Tag';
with    'HTML::StateTable::Role::Reorderable';
with    'HTML::StateTable::Role::Chartable';
#with    'HTML::StateTable::Role::Animation';

has '+caption' => default => 'Artist List';

has '+active_control_location' => default => 'BottomLeft';

has '+chartable_columns' => default => sub { ['upvotes'] };

has '+chartable_location' => default => 'Right';

has '+chartable_subtitle_link' => default => sub {
   return shift->context->uri_for_action('artist/list');
};

has '+chartable_type' => default => 'pie';

has '+configurable_action' => default => 'api/preference';

has '+download_display' => default => FALSE;

has '+form_control_location' => default => 'BottomLeft';

has '+form_buttons' => default => sub {
   return [{
      action    => 'artist/remove',
      selection => 'select_one',
      value     => 'Remove',
   }];
};

has '+icons' => default => sub { shift->context->icons_uri->as_string };

has '+page_control_location' => default => 'TopRight';

has '+tag_control_location' => default => 'Title';

has '+tag_section' => default => FALSE;

has '+title_location' => default => 'inner';

has 'list_id' => is => 'ro', isa => Int, predicate => 'has_list_id';

after 'BUILD' => sub {
   my $self = shift;

   if ($self->has_list_id) {
      my $list_rs   = $self->context->model('List');
      my $list_name = $list_rs->find($self->list_id)->name;

      $self->caption("Artists in List ${list_name}");
   }

   return;
};

set_table_name 'artists';

setup_resultset sub {
   my $self = shift;
   my $rs   = $self->context->model('Artist');

   return $rs unless $self->has_list_id;

   my $join_rs = $self->context->model('ListArtist');
   my $where   = { list_id => $self->list_id };

   $join_rs = $join_rs->search($where)->get_column('artistid');

   return $rs->search({ 'me.artistid' => { -in => $join_rs->as_query } });
};

has_column 'check' =>
   cell_traits => ['Checkbox'],
   label       => SPC,
   options     => { checkall => TRUE },
   value       => 'artistid';

has_column 'artistid' =>
   cell_traits => ['Numeric'],
   label       => 'ID',
   width       => '2rem';

has_column 'tags' =>
#   append_to   => 'name',
#   search_type => 'tag',
   displayed   => FALSE,
   searchable  => TRUE,
   sortable    => TRUE,
   value       => 'tag_string.name';

has_column 'name' =>
   label      => 'Artist Name',
   link       => sub {
      my $self    = shift;
      my $context = $self->table->context;

      return $context->uri_for_action('artist/view', [$self->result->id]);
   },
   searchable => TRUE,
   sortable   => TRUE,
   title      => 'Sort by artist',
   width      => '25rem';

has_column 'upvotes' =>
   cell_traits => ['Numeric'],
   label       => 'Upvotes',
   sortable    => TRUE,
   title       => 'Sort by upvotes';

has_column 'import_log_id', label => 'Import Id';

sub highlight_row {
   my ($self, $row) = @_;

   return $row->result->upvotes == 0 ? TRUE : FALSE;
}

use namespace::autoclean -except => TABLE_META;

1;
