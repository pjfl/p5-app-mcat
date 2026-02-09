package MCat::Table::View::List;

use HTML::StateTable::Constants qw( FALSE TRUE );
use Moo;

extends 'MCat::Table::View::Object';

has '+caption' => default => 'View List';

has '+form_buttons' => default => sub {
   my $self     = shift;
   my $context  = $self->context;
   my $object   = lc $self->result->core_table->name;
   my $obj_list = "${object}/list";
   my $id       = $self->result->id;

   return [{
      action    => $context->uri_for_action('list/list'),
      classes   => 'left',
      method    => 'get',
      selection => 'disable_on_select',
      value     => 'Lists',
   },{
      action    => $context->uri_for_action($obj_list, [], { list_id => $id }),
      classes   => 'left',
      method    => 'get',
      selection => 'disable_on_select',
      value     => 'View Content',
   },{
      action    => $context->uri_for_action('list/update', [$id]),
      method    => 'get',
      selection => 'disable_on_select',
      value     => 'Update List',
   },{
      action    => $context->uri_for_action('list/edit', [$id]),
      method    => 'get',
      selection => 'disable_on_select',
      value     => 'Edit',
   }];
};

use namespace::autoclean;

1;
