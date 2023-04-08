package MCat::Table::User::View;

use HTML::StateTable::Constants qw( FALSE TRUE );
use Moo;

extends 'MCat::Table::Object::View';

has '+form_buttons' => default => sub {
   my $self    = shift;
   my $context = $self->context;

   return [{
      action    => $context->uri_for_action('user/edit', [$self->result->id]),
      method    => 'get',
      selection => 'disable_on_select',
      value     => 'Edit User',
   },{
      action    => $context->uri_for_action('user/delete', [$self->result->id]),
      selection => 'disable_on_select',
      value     => 'Delete User',
   }];
};

use namespace::autoclean;

1;
