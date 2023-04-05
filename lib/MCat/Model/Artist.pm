package MCat::Model::Artist;

use HTML::Forms::Constants qw( EXCEPTION_CLASS );
use MCat::Util             qw( redirect );
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

      $context->stash( artist => $artist );
      $nav->crud('artist', $artistid)->item('cd/create', [$artistid]);
   }

   $nav->finalise;
   return;
}

sub create : Nav('Create Artist') {
   my ($self, $context) = @_;

   my $options = { context => $context, title => 'Create Artist' };
   my $form    = $self->form->new_with_context('Artist', $options);

   if ($form->process( posted => $context->posted )) {
      my $artistid    = $form->item->id;
      my $artist_view = $context->uri_for_action('artist/view', [$artistid]);
      my $message     = ['Artist [_1] created', $form->item->name];

      $context->stash( redirect $artist_view, $message );
   }

   $context->stash( form => $form );
   return;
}

sub delete : Nav('Delete Artist') {
   my ($self, $context, $artistid) = @_;

   return unless $self->has_valid_token($context);

   my $artist = $context->model('Artist')->find($artistid);

   return $self->error($context, UnknownArtist, [$artistid]) unless $artist;

   my $name = $artist->name;

   $artist->delete;

   my $artist_list = $context->uri_for_action('artist/list');

   $context->stash( redirect $artist_list, ['Artist [_1] deleted', $name] );
   return;
}

sub edit : Nav('Edit Artist') {
   my ($self, $context, $artistid) = @_;

   my $form = $self->form->new_with_context('Artist', {
      context => $context,
      item    => $context->stash('artist'),
      title   => 'Edit artist'
   });

   if ($form->process( posted => $context->posted )) {
      my $artist_view = $context->uri_for_action('artist/view', [$artistid]);
      my $message     = ['Artist [_1] updated', $form->item->name];

      $context->stash( redirect $artist_view, $message );
   }

   $context->stash( form => $form );
   return;
}

sub list : Nav('Artists') Auth('view') {
   my ($self, $context) = @_;

   $context->stash( table => $self->table->new_with_context('Artist', {
      context => $context, resultset => $context->model('Artist')
   }));
   return;
}

sub remove {
   my ($self, $context) = @_;

   return unless $self->has_valid_token($context);

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

sub view : Nav('View Artist') Auth('view') {
   my ($self, $context, $artistid) = @_;

   my $artist  = $context->stash('artist');
   my $cd_rs   = $context->model('Cd')->search({ 'me.artistid' => $artistid });
   my $options = { context => $context, resultset => $cd_rs };
   my $cds     = $self->table->new_with_context('Cd', $options);

   $context->stash(table => $self->table->new_with_context('Object::View', {
      add_columns => [ 'CDs' => $cds ], context => $context, result => $artist
   }));
   return;
}

1;
