package MCat::Table::Job;

use Moo;

extends 'App::Job::Table::Job';

has '+configurable_dialog_close' => default => sub {
   return shift->context->request->uri_for('img/cancel.svg')->as_string;
};

has '+configurable_label' => default => sub {
   return shift->context->request->uri_for('img/tune.svg')->as_string;
};

has '+form_buttons' => default => sub {
   return [{
      action    => 'job/remove',
      class     => 'remove-item',
      selection => 'select_one',
      value     => 'Remove Job',
   }];
};

use namespace::autoclean;

1;
