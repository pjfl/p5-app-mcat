package MCat::Model::Cd;

use HTML::Forms::Constants qw( EXCEPTION_CLASS NUL );
use MCat::Util             qw( redirect );
use Unexpected::Functions  qw( UnknownArtist UnknownCd Unspecified );
use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'cd';

sub base : Auth('view') {
   my ($self, $context, $id) = @_;

   my $method   = $context->endpoint;
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

   return unless $context->verify_form_post;

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

sub list : Auth('view') Nav('CDs|img/cd.svg') {
   my ($self, $context, $artistid) = @_;

   my $options = { context => $context };

   $options->{artistid} = $artistid if $artistid;

   if (my $list_id = $context->request->query_parameters->{list_id}) {
      $options->{list_id} = $list_id;
   }

   $context->stash(table => $self->table->new_with_context('Cd', $options));
   return;
}

sub view : Auth('view') Nav('View CD') {
   my ($self, $context, $cdid) = @_;

   my $options = { caption => NUL, context => $context, cdid => $cdid };
   my $tracks  = $self->table->new_with_context('Track', $options);

   $context->stash(table => $self->table->new_with_context('Object::View', {
      add_columns => [ 'Tracks' => $tracks ],
      caption     => 'CD View',
      context     => $context,
      result      => $context->stash('cd')
   }));
   return;
}

1;
