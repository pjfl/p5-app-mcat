package MCat::Table::Tag;

use HTML::StateTable::Constants qw( FALSE NUL SPC TABLE_META TRUE );
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';
with    'HTML::StateTable::Role::Configurable';
with    'HTML::StateTable::Role::Searchable';
with    'HTML::StateTable::Role::Filterable';
with    'HTML::StateTable::Role::CheckAll';
with    'HTML::StateTable::Role::Form';

has '+caption' => default => 'Tag List';

has '+configurable_action' => default => 'api/table_preference';

has '+configurable_control_location' => default => 'TopLeft';

has '+form_buttons' => default => sub {
   return [{
      action    => 'tag/remove',
      class     => 'remove-item',
      selection => 'select_one',
      value     => 'Remove Tag',
   }];
};

has '+form_control_location' => default => 'BottomRight';

has '+page_control_location' => default => 'TopRight';

has '+page_size_control_location' => default => 'BottomLeft';

set_table_name 'tag';

has_column 'id' =>
   cell_traits => ['Numeric'],
   label       => 'ID',
   width       => '2rem';

has_column 'name' =>
   filterable => TRUE,
   label      => 'Tag Name',
   link       => sub {
      my $self    = shift;
      my $context = $self->table->context;

      return  $context->uri_for_action('tag/view', [$self->result->id]);
   },
   searchable => TRUE,
   sortable   => TRUE,
   title      => 'Sort by tag',
   width      => '30rem';

has_column 'check' =>
   cell_traits => ['Checkbox'],
   label       => SPC,
   value       => 'id';

use namespace::autoclean -except => TABLE_META;

1;
