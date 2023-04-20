package MCat::Table::Artist;

use HTML::StateTable::Constants qw( FALSE NUL SPC TABLE_META TRUE );
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
with    'HTML::StateTable::Role::Animation';

has '+active_control_location' => default => 'BottomLeft';

has '+chartable_columns' => default => sub { ['upvotes'] };

has '+chartable_location' => default => 'Right';

has '+chartable_subtitle_link' => default => sub {
   return shift->context->uri_for_action('artist/list');
};

has '+chartable_type' => default => 'pie';

has '+configurable_dialog_close' => default => sub {
   return shift->context->request->uri_for('img/cancel.svg')->as_string;
};

has '+configurable_label' => default => sub {
   return shift->context->request->uri_for('img/tune.svg')->as_string;
};

has '+download_display' => default => FALSE;

has '+form_control_location' => default => 'BottomLeft';

has '+form_buttons' => default => sub {
   return [{
      action    => 'artist/remove',
      selection => 'select_one',
      value     => 'Remove Artist',
   }];
};

has '+page_control_location' => default => 'TopRight';

has '+tag_control_location' => default => 'Credit';

has '+tag_section' => default => FALSE;

has '+title_location' => default => 'outer';

set_table_name 'artist';

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

sub highlight_row {
   my ($self, $row) = @_;

   return $row->result->upvotes == 0 ? TRUE : FALSE;
}

use namespace::autoclean -except => TABLE_META;

1;
