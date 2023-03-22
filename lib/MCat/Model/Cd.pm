package MCat::Model::Cd;

use HTML::Forms::Constants qw( EXCEPTION_CLASS );
use MCat::Util             qw( redirect );
use Unexpected::Functions  qw( UnknownArtist UnknownCd Unspecified );
use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'cd';

sub base {
   my ($self, $context, $id) = @_;

   my $method   = (split m{ / }mx, $context->stash('action_path'))[-1];
   my $artistid = $id if $method eq 'create' || $method eq 'list';
   my $cdid     = $id if $method eq 'edit'   || $method eq 'view';
   my $nav      = $context->stash('nav');

   $nav->list('cd', 'CDs');

   if ($artistid) {
      my $artist = $context->model('Artist')->find($artistid);

      return $self->error($context, UnknownArtist, [$artistid]) unless $artist;

      $nav->item('artist/view', [$artistid])->item('cd/create', [$artistid]);
      $context->stash( artist => $artist );
   }

   if ($cdid) {
      my $cd = $context->model('Cd')->find($cdid);

      return $self->error($context, UnknownCd, [$cdid]) unless $cd;

      $nav->item('artist/view', [$cd->artistid]);
      $nav->crud('cd', $cdid, $cd->artistid)->item('track/create', [$cdid]);
      $context->stash( artist => $cd->artist, cd => $cd );
   }

   return;
}

sub create : Nav('Create CD') {
   my ($self, $context, $artistid) = @_;

   return $self->error($context, Unspecified, ['artistid']) unless $artistid;

   my $options = {
      artistid   => $artistid,
      context    => $context,
      item_class => 'Cd',
      title      => 'Create CD',
   };
   my $form = $self->form->new_with_context('Cd', $options);

   if ($form->process( posted => $context->posted )) {
      my $cd_view = $context->uri_for_action('cd/view', [$form->item->cdid]);
      my $message = ['CD [_1] created', $form->item->title];

      $context->stash( redirect $cd_view, $message );
   }

   $context->stash( form => $form );
   return;
}

sub delete : Nav('Delete CD') {
   my ($self, $context, $cdid) = @_;

   return unless $self->has_valid_token($context);

   my $cd       = $context->stash('cd');
   my $artistid = $cd->artistid;
   my $title    = $cd->title;

   $cd->delete;

   my $cd_list = $context->uri_for_action('cd/list', [$artistid]);

   $context->stash( redirect $cd_list, ['CD [_1] deleted', $title] );
   return;
}

sub edit : Nav('Edit CD') {
   my ($self, $context, $cdid) = @_;

   my $cd       = $context->stash('cd');
   my $options  = {
      artistid => $cd->artistid,
      context  => $context,
      item     => $cd,
      title    => 'Edit CD'
   };
   my $form = $self->form->new_with_context('Cd', $options);

   if ($form->process( posted => $context->posted )) {
      my $cd_view = $context->uri_for_action('cd/view', [$cdid]);
      my $message = ['CD [_1] updated', $form->item->title];

      $context->stash( redirect $cd_view, $message );
   }

   $context->stash( form => $form );
   return;
}

sub list : Nav('CDs') {
   my ($self, $context, $artistid) = @_;

   my $cd_rs = $context->model('Cd');

   $cd_rs = $cd_rs->search({ artistid => $artistid }) if $artistid;

   my $options = { context => $context, resultset => $cd_rs };

   $context->stash(table => $self->table->new_with_context('Cd', $options));
   return;
}

sub view : Nav('View CD') {
   my ($self, $context, $cdid) = @_;

   my $cd       = $context->stash('cd');
   my $track_rs = $context->model('Track')->search({ 'me.cdid' => $cdid });
   my $options  = { context => $context, resultset => $track_rs };

   $context->stash(table => $self->table->new_with_context('Track', $options));
   return;
}

1;
