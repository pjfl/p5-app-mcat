package MCat::Table::View::Filter;

use HTML::StateTable::Constants qw( FALSE TRUE );
use Moo;

extends 'MCat::Table::View::Object';

has '+caption' => default => 'Filter View';

has '+form_buttons' => default => sub {
   my $self    = shift;
   my $context = $self->context;

   return [{
      action    => $context->uri_for_action('filter/edit', [$self->result->id]),
      method    => 'get',
      selection => 'disable_on_select',
      value     => 'Edit',
   }];
};

use namespace::autoclean;

1;
