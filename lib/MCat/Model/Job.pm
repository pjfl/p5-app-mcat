package MCat::Model::Job;

use File::DataClass::Types qw( LoadableClass );
use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE TRUE );
use MCat::Util             qw( redirect redirect2referer );
use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'job';

has 'jobdaemon' => is => 'lazy', default => sub {
   return shift->jobdaemon_class->new(config => { appclass => 'MCat' });
};

has 'jobdaemon_class' => is => 'lazy', isa => LoadableClass, coerce => TRUE,
   default => 'MCat::JobServer';

sub base : Auth('admin') {
   my ($self, $context) = @_;

   my $nav = $context->stash('nav')->list('job');

   $nav->finalise;
   return;
}

1;
