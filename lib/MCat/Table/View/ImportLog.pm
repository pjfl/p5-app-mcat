package MCat::Table::View::ImportLog;

use HTML::StateTable::Constants qw( FALSE TRUE );
use Moo;

extends 'MCat::Table::View::Object';

has '+caption' => default => 'View Import Log';

has '+form_buttons' => default => sub {
   my $self      = shift;
   my $context   = $self->context;
   my $import_id = $self->result->import_id;

   return [{
      action    => $context->uri_for_action('import/view', [$import_id]),
      classes   => 'left',
      method    => 'get',
      selection => 'disable_on_select',
      value     => 'View Import',
   }];
};

use namespace::autoclean;

1;
