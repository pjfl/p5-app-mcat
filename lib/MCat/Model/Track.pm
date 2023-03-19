package MCat::Model::Track;

use HTML::Forms::Constants qw( EXCEPTION_CLASS );
use MCat::Util             qw( redirect );
use Unexpected::Functions  qw( UnknownTrack Unspecified );
use Web::Simple;

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'track';

sub base {
   my ($self, $context, $id) = @_;

   my $method  = (split m{ / }mx, $context->stash('action_path'))[-1];
   my $cdid    = $id if $method eq 'create' || $method eq 'list';
   my $trackid = $id if $method eq 'edit'   || $method eq 'view';
   my $nav     = $context->stash('nav');

   $nav->list('track',  'Tracks');
   $nav->item('Create', 'track/create', [$cdid])    if $cdid;
   $nav->item('View',   'track/view',   [$trackid]) if $trackid;
   $nav->item('CD',     'cd/view',      [$cdid])    if $cdid;
   return;
}

sub create {
   my ($self, $context, $cdid) = @_;

   return $self->error($context, Unspecified, ['cdid']) unless $cdid;

   my $options = {
      cdid       => $cdid,
      context    => $context,
      item_class => 'Track',
      title      => 'Create track'
   };
   my $form = $self->form->new_with_context('Track', $options);

   if ($form->process( posted => $context->posted )) {
      my $track_view = $context->uri_for_action('track/view',[$form->item->id]);
      my $message    = ['Track [_1] created', $form->item->title];

      $context->stash( redirect $track_view, $message );
   }

   $context->stash( cdid => $cdid, form => $form );
   return;
}

sub delete {
   my ($self, $context, $trackid) = @_;

   return unless $self->has_valid_token($context);

   return $self->error($context, Unspecified, ['trackid']) unless $trackid;

   my $track = $context->model('Track')->find($trackid);

   return $self->error($context, UnknownTrack, [$trackid]) unless $track;

   my $cdid  = $track->cdid;
   my $title = $track->title;

   $track->delete;

   my $cd_view = $context->uri_for_action('cd/view', [$cdid]);

   $context->stash( redirect $cd_view, ['Track [_1] deleted', $title] );
   return;
}

sub edit {
   my ($self, $context, $trackid) = @_;

   return $self->error($context, Unspecified, ['trackid']) unless $trackid;

   my $track = $context->model('Track')->find($trackid);

   return $self->error($context, UnknownTrack, [$trackid]) unless $track;

   my $cdid    = $track->cd->cdid;
   my $options = {
      cdid    => $cdid,
      context => $context,
      item    => $track,
      title   => 'Edit track'
   };
   my $form    = $self->form->new_with_context('Track', $options);

   if ($form->process( posted => $context->posted )) {
      my $track_view = $context->uri_for_action('track/view', [$trackid]);
      my $message    = ['Track [_1] updated', $form->item->title];

      $context->stash( redirect $track_view, $message );
   }

   $context->stash('nav')->item('Create', 'track/create', [$cdid]);
   $context->stash('nav')->item('CD', 'cd/view', [$cdid]);
   $context->stash( cdid => $cdid, trackid => $trackid, form => $form );
   return;
}

sub list {
   my ($self, $context, $cdid) = @_;

   my $track_rs = $context->model('Track');

   if ($cdid) {
      $track_rs = $track_rs->search({ artistid => $cdid });
      $context->stash(cdid => $cdid);
   }

   my $options = { context => $context, resultset => $track_rs };

   $context->stash(table => $self->table->new_with_context('Track', $options));
   return;
}

sub view {
   my ($self, $context, $trackid) = @_;

   return $self->error($context, Unspecified, ['trackid']) unless $trackid;

   my $track = $context->model('Track')->find($trackid);

   return $self->error($context, UnknownTrack, [$trackid]) unless $track;

   my $cdid = $track->cd->id;

   $context->stash('nav')->item('Create', 'track/create', [$cdid]);
   $context->stash('nav')->item('CD', 'cd/view', [$cdid]);
   $context->stash( cdid => $cdid, track => $track );
   return;
}

use namespace::autoclean;

1;
