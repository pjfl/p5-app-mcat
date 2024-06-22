package MCat::Model::Artist;

use HTML::Forms::Constants qw( EXCEPTION_CLASS NUL );
use MCat::Util             qw( redirect redirect2referer );
use Unexpected::Functions  qw( UnknownArtist Unspecified );
use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'artist';

sub base : Auth('view') {
   my ($self, $context, $artistid) = @_;

   my $nav = $context->stash('nav')->list('artist')->item('artist/create');

   if ($artistid) {
      my $artist = $context->model('Artist')->find($artistid);

      return $self->error($context, UnknownArtist, [$artistid]) unless $artist;

      $context->stash(artist => $artist);
      $nav->crud('artist', $artistid)->item('cd/create', [$artistid]);
   }

   $nav->finalise;
   return;
}

sub create : Nav('Create Artist') {
   my ($self, $context) = @_;

   my $options = { context => $context, title => 'Create Artist' };
   my $form    = $self->new_form('Artist', $options);

   if ($form->process(posted => $context->posted)) {
      my $view    = $context->uri_for_action('artist/view', [$form->item->id]);
      my $message = ['Artist [_1] created', $form->item->name];

      $context->stash(redirect $view, $message);
   }

   $context->stash(form => $form);
   return;
}

sub delete : Nav('Delete Artist') {
   my ($self, $context, $artistid) = @_;

   return unless $context->verify_form_post;

   my $artist = $context->stash('artist');

   return $self->error($context, UnknownArtist, [$artistid]) unless $artist;

   my $name = $artist->name;

   $artist->delete;

   my $list = $context->uri_for_action('artist/list');

   $context->stash(redirect $list, ['Artist [_1] deleted', $name]);
   return;
}

sub edit : Nav('Edit Artist') {
   my ($self, $context) = @_;

   my $artist  = $context->stash('artist');
   my $options = {context => $context, item => $artist, title => 'Edit artist'};
   my $form    = $self->new_form('Artist', $options);

   if ($form->process(posted => $context->posted)) {
      my $view = $context->uri_for_action('artist/view', [$artist->artistid]);
      my $message = ['Artist [_1] updated', $form->item->name];

      $context->stash(redirect $view, $message);
   }

   $context->stash(form => $form);
   return;
}

sub list : Auth('view') Nav('Artists|img/artist.svg') {
   my ($self, $context) = @_;

   my $options = { context => $context };

   if (my $list_id = $context->request->query_parameters->{list_id}) {
      $options->{list_id} = $list_id;
   }

   $context->stash(table => $self->new_table('Artist', $options));
   return;
}

sub remove {
   my ($self, $context) = @_;

   return unless $context->verify_form_post;

   my $value = $context->request->body_parameters->{data} or return;
   my $rs    = $context->model('Artist');
   my $count = 0;

   for my $artist (grep { $_ } map { $rs->find($_) } @{$value->{selector}}) {
      $artist->delete;
      $count++;
   }

   $context->stash(redirect2referer $context, ["${count} artist(s) deleted"]);
   return;
}

sub view : Auth('view') Nav('View Artist') {
   my ($self, $context) = @_;

   my $artist  = $context->stash('artist');
   my $options = {
      caption => NUL, context => $context, artistid => $artist->artistid
   };
   my $cds     = $self->new_table('Cd', $options);

   $context->stash(table => $self->new_table('Object::View', {
      add_columns => [ 'CDs' => $cds ],
      caption     => 'Artist View',
      context     => $context,
      result      => $artist
   }));
   return;
}

1;
