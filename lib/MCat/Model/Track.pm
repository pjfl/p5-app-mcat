package MCat::Model::Track;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE TRUE );
use MCat::Util             qw( redirect );
use Unexpected::Functions  qw( UnknownCd UnknownTrack Unspecified );
use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'track';

sub base : Auth('view') {
   my ($self, $context) = @_;

   $context->stash('nav')->list('track')->finalise;

   return;
}

sub cd : Auth('view') Capture(1) {
   my ($self, $context, $cdid) = @_;

   my $cd = $context->model('Cd')->find($cdid);

   return $self->error($context, UnknownCd, [$cdid]) unless $cd;

   $context->stash(cd => $cd);

   my $nav = $context->stash('nav')->list('track');

   $nav->item('cd/view', [$cd->cdid])->item('track/create', [$cd->cdid]);
   $nav->finalise;
   return;
}

sub track : Auth('view') Capture(1) {
   my ($self, $context, $trackid) = @_;

   my $options = { prefetch => { 'cd' => 'artist' } };
   my $track   = $context->model('Track')->find($trackid, $options);

   return $self->error($context, UnknownTrack, [$trackid]) unless $track;

   $context->stash(cd => $track->cd, track => $track);

   my $nav = $context->stash('nav')->list('track');

   $nav->item('cd/view', [$track->cdid]);
   $nav->crud('track', $track->trackid, $track->cdid)->finalise;
   return;
}

sub create : Nav('Create Track') {
   my ($self, $context) = @_;

   my $cd   = $context->stash('cd');
   my $form = $self->new_form('Track', {
      cdid       => $cd->cdid,
      context    => $context,
      item_class => 'Track',
      title      => 'Create track'
   });

   if ($form->process(posted => $context->posted)) {
      my $trackid    = $form->item->trackid;
      my $track_view = $context->uri_for_action('track/view', [$trackid]);
      my $message    = ['Track [_1] created', $form->item->title];

      $context->stash(redirect $track_view, $message);
   }

   $context->stash(form => $form);
   return;
}

sub delete : Nav('Delete Track') {
   my ($self, $context) = @_;

   return unless $self->verify_form_post($context);

   my $track = $context->stash('track');
   my $cdid  = $track->cdid;
   my $title = $track->title;

   $track->delete;

   my $cd_view = $context->uri_for_action('cd/view', [$cdid]);

   $context->stash(redirect $cd_view, ['Track [_1] deleted', $title]);
   return;
}

sub edit : Nav('Edit Track') {
   my ($self, $context) = @_;

   my $track = $context->stash('track');
   my $form  = $self->new_form('Track', {
      cdid    => $track->cdid,
      context => $context,
      item    => $track,
      title   => 'Edit track'
   });

   if ($form->process(posted => $context->posted)) {
      my $track_view = $context->uri_for_action('track/view',[$track->trackid]);
      my $message    = ['Track [_1] updated', $form->item->title];

      $context->stash(redirect $track_view, $message);
   }

   $context->stash(form => $form);
   return;
}

sub list : Auth('view') Nav('Tracks|img/tracks.svg') {
   my ($self, $context) = @_;

   my $options = { context => $context };
   my $cd      = $context->stash('cd');

   $options->{cdid} = $cd->cdid if $cd;

   if (my $list_id = $context->request->query_parameters->{list_id}) {
      $options->{list_id} = $list_id;
   }

   $context->stash(table => $self->new_table('Track', $options));
   return;
}

sub view : Auth('view') Nav('View Track') {
   my ($self, $context) = @_;

   my $track   = $context->stash('track');
   my $artist  = $track->cd->artist->name;
   my $buttons = [{
      action    => $context->uri_for_action('cd/view', [$track->cdid]),
      method    => 'get',
      selection => 'disable_on_select',
      value     => 'CD',
   },{
      action    => $context->uri_for_action('track/edit', [$track->trackid]),
      classes   => 'right',
      method    => 'get',
      selection => 'disable_on_select',
      value     => 'Edit',
   }];

   $context->stash(table => $self->new_table('View::Object', {
      add_columns       => [ 'Artist' => $artist ],
      add_columns_first => TRUE,
      caption           => 'Track View',
      context           => $context,
      form_buttons      => $buttons,
      result            => $track,
   }));
   return;
}

1;
