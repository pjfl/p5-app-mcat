package MCat::Model::Cd;

use HTML::Forms::Constants qw( EXCEPTION_CLASS );
use MCat::Util             qw( redirect );
use Unexpected::Functions  qw( UnknownArtist UnknownCd Unspecified );
use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'cd';

sub base : Auth('view') {
   my ($self, $context, $id) = @_;

   my $method   = (split m{ / }mx, $context->stash('method_chain'))[-1];
   my $artistid = $id if $method eq 'create' || $method eq 'list';
   my $cdid     = $id if $method eq 'edit'   || $method eq 'view';
   my $nav      = $context->stash('nav')->list('cd');

   if ($artistid) {
      my $artist = $context->model('Artist')->find($artistid);

      return $self->error($context, UnknownArtist, [$artistid]) unless $artist;

      $context->stash( artist => $artist );
      $nav->item('artist/view', [$artistid])->item('cd/create', [$artistid]);
   }

   if ($cdid) {
      my $cd = $context->model('Cd')->find($cdid);

      return $self->error($context, UnknownCd, [$cdid]) unless $cd;

      $context->stash( artist => $cd->artist, cd => $cd );
      $nav->item('artist/view', [$cd->artistid]);
      $nav->crud('cd', $cdid, $cd->artistid)->item('track/create', [$cdid]);
   }

   $nav->finalise;
   return;
}

sub create : Nav('Create CD') {
   my ($self, $context, $artistid) = @_;

   return $self->error($context, Unspecified, ['artistid']) unless $artistid;

   my $form = $self->form->new_with_context('Cd', {
      artistid   => $artistid,
      context    => $context,
      item_class => 'Cd',
      title      => 'Create CD',
   });

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

   my $cd = $context->model('Cd')->find($cdid);

   return $self->error($context, UnknownCd, [$cdid]) unless $cd;

   my $artistid = $cd->artistid;
   my $title    = $cd->title;

   $cd->delete;

   my $cd_list = $context->uri_for_action('artist/view', [$artistid]);

   $context->stash( redirect $cd_list, ['CD [_1] deleted', $title] );
   return;
}

sub edit : Nav('Edit CD') {
   my ($self, $context, $cdid) = @_;

   my $cd   = $context->stash('cd');
   my $form = $self->form->new_with_context('Cd', {
      artistid => $cd->artistid,
      context  => $context,
      item     => $cd,
      title    => 'Edit CD'
   });

   if ($form->process( posted => $context->posted )) {
      my $cd_view = $context->uri_for_action('cd/view', [$cdid]);
      my $message = ['CD [_1] updated', $form->item->title];

      $context->stash( redirect $cd_view, $message );
   }

   $context->stash( form => $form );
   return;
}

sub list : Nav('CDs') Auth('view') {
   my ($self, $context, $artistid) = @_;

   my $cd_rs = $context->model('Cd');

   $cd_rs = $cd_rs->search({ 'me.artistid' => $artistid }) if $artistid;

   $context->stash(table => $self->table->new_with_context('Cd', {
      context => $context, resultset => $cd_rs
   }));
   return;
}

sub view : Nav('View CD') Auth('view') {
   my ($self, $context, $cdid) = @_;

   my $cd       = $context->stash('cd');
   my $track_rs = $context->model('Track')->search({ 'me.cdid' => $cdid });
   my $options  = { context => $context, resultset => $track_rs };
   my $tracks   = $self->table->new_with_context('Track', $options);

   $context->stash(table => $self->table->new_with_context('Object::View', {
      add_columns => [ 'Tracks' => $tracks ], context => $context, result => $cd
   }));
   return;
}

1;
