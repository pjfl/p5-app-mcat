package MCat::Table::User;

use HTML::StateTable::Constants qw( FALSE NUL SPC TABLE_META TRUE );
use MCat::Util                  qw( local_tz );
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';
with    'HTML::StateTable::Role::Configurable';
with    'HTML::StateTable::Role::Searchable';
with    'HTML::StateTable::Role::CheckAll';
with    'HTML::StateTable::Role::Form';
with    'HTML::StateTable::Role::Active';

has '+active_control_location' => default => 'BottomLeft';

has '+caption' => default => 'User List';

has '+configurable_action' => default => 'api/table_preference';

has '+configurable_control_location' => default => 'TopRight';

has '+form_buttons' => default => sub {
   return [{
      action    => 'user/remove',
      class     => 'remove-item',
      selection => 'select_one',
      value     => 'Remove User',
   }];
};

has '+form_control_location' => default => 'BottomRight';

has '+icons' => default => sub {
   return shift->context->request->uri_for('img/icons.svg')->as_string;
};

has '+page_control_location' => default => 'TopRight';

has '+page_size_control_location' => default => 'BottomLeft';

set_table_name 'user';

has_column 'id' =>
   cell_traits => ['Numeric'],
   label       => 'ID',
   width       => '3rem';

has_column 'name' =>
   label      => 'User Name',
   link       => sub {
      my $self    = shift;
      my $context = $self->table->context;

      return  $context->uri_for_action('user/view', [$self->result->id]);
   },
   searchable => TRUE,
   sortable   => TRUE,
   title      => 'Sort by user',
   width      => '10rem';

has_column 'role_id' =>
   cell_traits => ['Capitalise'],
   label       => 'Role',
   searchable  => TRUE,
   sortable    => TRUE,
   title       => 'Sort by role',
   value       => 'role.name';

has_column 'timezone' =>
   value => sub {
      my $self    = shift;
      my $profile = $self->result->profile;

      return $profile ? $profile->preference('timezone') : local_tz;
   },
   width => '15rem';

has_column 'check' =>
   cell_traits => ['Checkbox'],
   label       => SPC,
   value       => 'id';

use namespace::autoclean -except => TABLE_META;

1;
