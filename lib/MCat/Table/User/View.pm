package MCat::Table::User::View;

use HTML::StateTable::Constants qw( FALSE TRUE );
use Moo;

extends 'MCat::Table::Object::View';

has '+caption' => default => 'User View';

has '+form_buttons' => default => sub {
   my $self    = shift;
   my $context = $self->context;

   return [{
      action    => $context->uri_for_action('user/edit', [$self->result->id]),
      method    => 'get',
      selection => 'disable_on_select',
      value     => 'Edit',
   },{
      action    => $context->uri_for_action('user/profile', [$self->result->id]),
      method    => 'get',
      selection => 'disable_on_select',
      value     => 'Profile',
   },{
      action    => $context->uri_for_action('user/delete', [$self->result->id]),
      classes   => 'right',
      selection => 'disable_on_select',
      value     => 'Delete',
   }];
};

use namespace::autoclean;

1;
