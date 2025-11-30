package MCat::Table::Job;

use Moo;

extends 'App::Job::Table::Job';

has '+configurable_control_location' => default => 'TopRight';

has '+page_control_location' => default => 'TopLeft';

has '+form_buttons' => default => sub {
   return [{
      action    => 'job/remove',
      class     => 'remove-item',
      selection => 'select_one',
      value     => 'Remove Job',
   }];
};

has '+form_classes' => default => sub { ['classic', 'fieldset'] };

has '+icons' => default => sub { shift->context->icons_uri->as_string };

use namespace::autoclean;

1;
