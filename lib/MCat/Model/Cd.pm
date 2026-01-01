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
   my ($self, $context) = @_;

   $context->stash('nav')->list('cd')->finalise;

   return;
}

sub artist : Auth('view') Capture(1) {
   my ($self, $context, $artistid) = @_;

   my $artist = $context->model('Artist')->find($artistid);

   return $self->error($context, UnknownArtist, [$artistid]) unless $artist;

   $context->stash(artist => $artist);

   my $nav = $context->stash('nav')->list('cd');

   $nav->item('artist/view', [$artist->artistid]);
   $nav->item('cd/create', [$artist->artistid])->finalise;
   return;
}

sub cd : Auth('view') Capture(1) {
   my ($self, $context, $cdid) = @_;

   my $cd = $context->model('Cd')->find($cdid);

   return $self->error($context, UnknownCd, [$cdid]) unless $cd;

   $context->stash(artist => $cd->artist, cd => $cd);

   my $nav = $context->stash('nav')->list('cd');

   $nav->item('artist/view', [$cd->artistid]);
   $nav->crud('cd', $cd->cdid, $cd->artistid);
   $nav->item('track/create', [$cd->cdid])->finalise;
   return;
}

sub create : Nav('Create CD') {
   my ($self, $context) = @_;

   my $artist = $context->stash('artist');
   my $form   = $self->form->new_with_context('Cd', {
      artistid   => $artist->artistid,
      context    => $context,
      item_class => 'Cd',
      title      => 'Create CD',
   });

   if ($form->process(posted => $context->posted)) {
      my $cd_view = $context->uri_for_action('cd/view', [$form->item->cdid]);
      my $message = ['CD [_1] created', $form->item->title];

      $context->stash(redirect $cd_view, $message);
   }

   $context->stash(form => $form);
   return;
}

sub delete : Nav('Delete CD') {
   my ($self, $context) = @_;

   return unless $self->verify_form_post($context);

   my $cd       = $context->stash('cd');
   my $artistid = $cd->artistid;
   my $title    = $cd->title;

   $cd->delete;

   my $cd_list = $context->uri_for_action('artist/view', [$artistid]);

   $context->stash(redirect $cd_list, ['CD [_1] deleted', $title]);
   return;
}

sub edit : Nav('Edit CD') {
   my ($self, $context) = @_;

   my $cd   = $context->stash('cd');
   my $form = $self->form->new_with_context('Cd', {
      artistid => $cd->artistid,
      context  => $context,
      item     => $cd,
      title    => 'Edit CD'
   });

   if ($form->process(posted => $context->posted)) {
      my $cd_view = $context->uri_for_action('cd/view', [$cd->cdid]);
      my $message = ['CD [_1] updated', $form->item->title];

      $context->stash(redirect $cd_view, $message);
   }

   $context->stash(form => $form);
   return;
}

sub list : Auth('view') Nav('CDs|img/cd.svg') {
   my ($self, $context) = @_;

   my $options = { context => $context };
   my $artist  = $context->stash('artist');

   $options->{artistid} = $artist->artistid if $artist;

   if (my $list_id = $context->request->query_parameters->{list_id}) {
      $options->{list_id} = $list_id;
   }

   $context->stash(table => $self->table->new_with_context('Cd', $options));
   return;
}

sub view : Auth('view') Nav('View CD') {
   my ($self, $context) = @_;

   my $cd      = $context->stash('cd');
   my $options = { caption => NUL, context => $context, cdid => $cd->cdid };
   my $tracks  = $self->table->new_with_context('Track', $options);
   my $buttons = [{
      action    => $context->uri_for_action('artist/view', [$cd->artistid]),
      method    => 'get',
      selection => 'disable_on_select',
      value     => 'Artist',
   },{
      action    => $context->uri_for_action('cd/edit', [$cd->cdid]),
      classes   => 'right',
      method    => 'get',
      selection => 'disable_on_select',
      value     => 'Edit',
   }];

   $context->stash(table => $self->table->new_with_context('View::Object', {
      add_columns  => [ 'Tracks' => $tracks ],
      caption      => 'CD View',
      context      => $context,
      form_buttons => $buttons,
      result       => $cd,
   }));
   return;
}

1;
