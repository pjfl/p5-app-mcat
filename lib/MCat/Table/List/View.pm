package MCat::Table::List::View;

use HTML::StateTable::Constants qw( FALSE TRUE );
use Moo;

extends 'MCat::Table::Object::View';

has '+caption' => default => 'List View';

has '+form_buttons' => default => sub {
   my $self        = shift;
   my $context     = $self->context;
   my $object      = lc $self->result->core_table->name;
   my $object_list = "${object}/list";
   my $id          = $self->result->id;

   return [{
      action => $context->uri_for_action('list/update', [$id]),
      method => 'get',
      value  => 'Update List',
   },{
      action => $context->uri_for_action($object_list, [], { list_id => $id }),
      method => 'get',
      value  => 'View Content',
   }];
};

use namespace::autoclean;

1;
