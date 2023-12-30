package MCat::Table::List::View;

use HTML::StateTable::Constants qw( FALSE TRUE );
use Moo;

extends 'MCat::Table::Object::View';

has '+caption' => default => 'List View';

has '+form_buttons' => default => sub {
   my $self    = shift;
   my $context = $self->context;

   return [{
      action    => $context->uri_for_action('list/update', [$self->result->id]),
      method    => 'get',
      selection => 'disable_on_select',
      value     => 'Update List',
   }];
};

use namespace::autoclean;

1;
