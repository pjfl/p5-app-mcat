package MCat::Model::Artist;

use HTML::Forms::Constants qw( EXCEPTION_CLASS );
use MCat::Util             qw( redirect );
use Unexpected::Functions  qw( UnknownArtist Unspecified );
use Web::Simple;

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'artist';

sub base {
   my ($self, $context, $artistid) = @_;

   my $nav = $context->stash('nav');

   $nav->list('artist', 'Artists')->item('Create', 'artist/create');

   return unless $artistid;

   $nav->crud('artist', $artistid);
   $nav->item('Create CD', 'cd/create', [$artistid]);

   my $artist = $context->model('Artist')->find($artistid);

   return $self->error($context, UnknownArtist, [$artistid]) unless $artist;

   $context->stash(artist => $artist);
   return;
}

sub create {
   my ($self, $context) = @_;

   my $options = {
      context => $context, item_class => 'Artist', title => 'Create artist'
   };
   my $form = $self->form->new_with_context('Artist', $options);

   if ($form->process( posted => $context->posted )) {
      my $artistid    = $form->item->id;
      my $artist_view = $context->uri_for_action('artist/view', [$artistid]);
      my $message     = ['Artist [_1] created', $form->item->name];

      $context->stash( redirect $artist_view, $message );
      return;
   }

   $context->stash( form => $form );
   return;
}

sub delete {
   my ($self, $context, $artistid) = @_;

   return unless $self->has_valid_token($context);

   my $artist = $context->stash('artist');
   my $name   = $artist->name;

   $artist->delete;

   my $artist_list = $context->uri_for_action('artist/list');

   $context->stash( redirect $artist_list, ['Artist [_1] deleted', $name] );
   return;
}

sub edit {
   my ($self, $context, $artistid) = @_;

   my $artist  = $context->stash('artist');
   my $options = {
      context => $context, item => $artist, title => 'Edit artist'
   };
   my $form = $self->form->new_with_context('Artist', $options);

   if ($form->process( posted => $context->posted )) {
      my $artist_view = $context->uri_for_action('artist/view', [$artistid]);
      my $message     = ['Artist [_1] updated', $form->item->name];

      $context->stash( redirect $artist_view, $message );
      return;
   }

   $context->stash( form => $form );
   return;
}

sub list {
   my ($self, $context) = @_;

   my $options = { context => $context, resultset => $context->model('Artist')};

   $context->stash( table => $self->table->new_with_context('Artist',$options));
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

   $context->stash( response => { message => "${count} artist(s) deleted" } );
   return;
}

sub view {
   my ($self, $context, $artistid) = @_;

   my $artist  = $context->stash('artist');
   my $cd_rs   = $context->model('Cd')->search({ artistid => $artistid });
   my $options = { context => $context, resultset => $cd_rs };

   $context->stash( table => $self->table->new_with_context('Cd', $options));
   return;
}

use namespace::autoclean;

1;
