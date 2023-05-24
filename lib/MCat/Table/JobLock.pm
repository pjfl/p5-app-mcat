package MCat::Table::JobLock;

use Moo;

extends 'App::Job::Table::JobLock';

has '+form_buttons' => default => sub {
   return [{
      action    => 'job/remove',
      class     => 'remove-item',
      selection => 'select_one',
      value     => 'Remove Lock',
   }];
};

1;
