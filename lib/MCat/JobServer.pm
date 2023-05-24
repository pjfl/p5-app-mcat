package MCat::JobServer;

use App::Job::Daemon; our $VERSION = App::Job::Daemon->VERSION;

use Moo;

extends 'App::Job::Daemon';

has '+config_class' => default => 'MCat::Config';

has '+log_class' => default => 'MCat::Log';

use namespace::autoclean;

1;
