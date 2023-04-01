package MCat::Table::User;

use HTML::StateTable::Constants qw( FALSE NUL SPC TABLE_META TRUE );
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';
with    'HTML::StateTable::Role::Searchable';
with    'HTML::StateTable::Role::Configurable';
with    'HTML::StateTable::Role::Filterable';
with    'HTML::StateTable::Role::CheckAll';
with    'HTML::StateTable::Role::Form';

has '+form_buttons' => default => sub {
   return [{
      action    => 'user/remove',
      class     => 'remove-item',
      selection => 'select_one',
      value     => 'Remove User',
   }];
};

set_table_name 'user';

has_column 'check' =>
   cell_traits => ['Checkbox'],
   label       => SPC,
   options     => { checkall => TRUE },
   value       => 'id';

has_column 'id' =>
   cell_traits => ['Numeric'],
   label       => 'ID',
   width       => '40px';

has_column 'name' =>
   filterable => TRUE,
   label      => 'User Name',
   link       => sub {
      my $self    = shift;
      my $context = $self->table->context;

      return  $context->uri_for_action('user/view', [$self->result->id]);
   },
   searchable => TRUE,
   sortable   => TRUE,
   title      => 'Sort by user';

use namespace::autoclean -except => TABLE_META;

1;