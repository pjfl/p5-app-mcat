package MCat::Table::View::Import;

use HTML::StateTable::Constants qw( FALSE TRUE );
use Moo;

extends 'MCat::Table::View::Object';

has '+caption' => default => 'Import View';

has '+form_buttons' => default => sub {
   my $self    = shift;
   my $context = $self->context;
   my $id      = $self->result->id;

   return [{
      action    => $context->uri_for_action('import/list'),
      method    => 'get',
      selection => 'disable_on_select',
      value     => 'List',
   },{
      action    => $context->uri_for_action('import/update', [$id]),
      selection => 'disable_on_select',
      value     => 'Update',
   },{
      action    => $context->uri_for_action('import/edit', [$id]),
      classes   => 'right',
      method    => 'get',
      selection => 'disable_on_select',
      value     => 'Edit',
   }];
};

use namespace::autoclean;

1;
