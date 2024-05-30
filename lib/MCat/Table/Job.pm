package MCat::Table::Job;

use Moo;

extends 'App::Job::Table::Job';

has '+form_buttons' => default => sub {
   return [{
      action    => 'job/remove',
      class     => 'remove-item',
      selection => 'select_one',
      value     => 'Remove Job',
   }];
};

has '+icons' => default => sub {
   return shift->context->request->uri_for('img/icons.svg')->as_string;
};

use namespace::autoclean;

1;
