package MCat::Model::Track;

use HTML::Forms::Constants qw( EXCEPTION_CLASS );
use MCat::Util             qw( redirect );
use Unexpected::Functions  qw( UnknownCd UnknownTrack Unspecified );
use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'track';

sub base : Auth('view') {
   my ($self, $context, $id) = @_;

   my $method  = (split m{ / }mx, $context->stash('method_chain'))[-1];
   my $cdid    = $id if $method eq 'create' || $method eq 'list';
   my $trackid = $id if $method eq 'edit'   || $method eq 'view';
   my $nav     = $context->stash('nav')->list('track');

   if ($cdid) {
      my $cd = $context->model('Cd')->find($cdid);

      return $self->error($context, UnknownCd, [$cdid]) unless $cd;

      $context->stash(cd => $cd);
      $nav->item('cd/view', [$cdid])->item('track/create', [$cdid]);
   }

   if ($trackid) {
      my $track = $context->model('Track')->find($trackid);

      return $self->error($context, UnknownTrack, [$trackid]) unless $track;

      $context->stash(cd => $track->cd, track => $track);
      $nav->item('cd/view', [$track->cdid]);
      $nav->crud('track', $trackid, $track->cdid);
   }

   $nav->finalise;
   return;
}

sub create : Nav('Create Track') {
   my ($self, $context, $cdid) = @_;

   return $self->error($context, Unspecified, ['cdid']) unless $cdid;

   my $form = $self->form->new_with_context('Track', {
      cdid       => $cdid,
      context    => $context,
      item_class => 'Track',
      title      => 'Create track'
   });

   if ($form->process( posted => $context->posted )) {
      my $trackid    = $form->item->trackid;
      my $track_view = $context->uri_for_action('track/view', [$trackid]);
      my $message    = ['Track [_1] created', $form->item->title];

      $context->stash( redirect $track_view, $message );
   }

   $context->stash( form => $form );
   return;
}

sub delete : Nav('Delete Track') {
   my ($self, $context, $trackid) = @_;

   return unless $self->verify_form_post($context);

   my $track = $context->model('Track')->find($trackid);

   return $self->error($context, UnknownTrack, [$trackid]) unless $track;

   my $cdid  = $track->cdid;
   my $title = $track->title;

   $track->delete;

   my $cd_view = $context->uri_for_action('cd/view', [$cdid]);

   $context->stash( redirect $cd_view, ['Track [_1] deleted', $title] );
   return;
}

sub edit : Nav('Edit Track') {
   my ($self, $context, $trackid) = @_;

   my $track = $context->stash('track');
   my $form  = $self->form->new_with_context('Track', {
      cdid    => $track->cdid,
      context => $context,
      item    => $track,
      title   => 'Edit track'
   });

   if ($form->process( posted => $context->posted )) {
      my $track_view = $context->uri_for_action('track/view', [$trackid]);
      my $message    = ['Track [_1] updated', $form->item->title];

      $context->stash( redirect $track_view, $message );
   }

   $context->stash( form => $form );
   return;
}

sub list : Auth('view') Nav('Tracks|img/tracks.svg') {
   my ($self, $context, $cdid) = @_;

   my $options = { context => $context };

   $options->{cdid} = $cdid if $cdid;

   if (my $list_id = $context->request->query_parameters->{list_id}) {
      $options->{list_id} = $list_id;
   }

   $context->stash(table => $self->table->new_with_context('Track', $options));
   return;
}

sub view : Auth('view') Nav('View Track') {
   my ($self, $context, $trackid) = @_;

   my $track   = $context->stash('track');
   my $buttons = [{
      action    => $context->uri_for_action('cd/view', [$track->cdid]),
      method    => 'get',
      selection => 'disable_on_select',
      value     => 'CD',
   },{
      action    => $context->uri_for_action('track/edit', [$trackid]),
      classes   => 'right',
      method    => 'get',
      selection => 'disable_on_select',
      value     => 'Edit',
   }];

   $context->stash(table => $self->table->new_with_context('View::Object', {
      caption      => 'Track View',
      context      => $context,
      form_buttons => $buttons,
      result       => $track,
   }));
   return;
}

1;
