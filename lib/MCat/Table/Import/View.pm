package MCat::Table::Import::View;

use HTML::StateTable::Constants qw( FALSE TRUE );
use Moo;

extends 'MCat::Table::Object::View';

has '+caption' => default => 'Import View';

has '+form_buttons' => default => sub {
   my $self    = shift;
   my $context = $self->context;
   my $id      = $self->result->id;

   return [{
      action    => $context->uri_for_action('import/edit', [$id]),
      method    => 'get',
      selection => 'disable_on_select',
      value     => 'Edit',
   }, {
      action    => $context->uri_for_action('import/delete', [$id]),
      selection => 'disable_on_select',
      value     => 'Delete',
   }];
};

use namespace::autoclean;

1;
