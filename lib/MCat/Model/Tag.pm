package MCat::Model::Tag;

use HTML::Forms::Constants qw( EXCEPTION_CLASS );
use MCat::Util             qw( redirect );
use Unexpected::Functions  qw( UnknownTag Unspecified );
use Web::Simple;

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'tag';

sub base {
   my ($self, $context, $tagid) = @_;

   my $nav = $context->stash('nav');

   $nav->list('tag', 'Tags')->item('Create', 'tag/create');

   return unless $tagid;

   $nav->crud('tag', $tagid);

   my $tag = $context->model('Tag')->find($tagid);

   return $self->error($context, UnknownTag, [$tagid]) unless $tag;

   $context->stash(tag => $tag);
   return;
}

sub create {
   my ($self, $context) = @_;

   my $options = {
      context => $context, item_class => 'Tag', title => 'Create Tag'
   };
   my $form = $self->form->new_with_context('Tag', $options);

   if ($form->process( posted => $context->posted )) {
      my $tagid    = $form->item->id;
      my $tag_view = $context->uri_for_action('tag/view', [$tagid]);
      my $message  = ['Tag [_1] created', $form->item->name];

      $context->stash( redirect $tag_view, $message );
      return;
   }

   $context->stash( form => $form );
   return;
}

sub delete {
   my ($self, $context, $tagid) = @_;

   return unless $self->has_valid_token($context);

   my $tag  = $context->stash('tag');
   my $name = $tag->name;

   $tag->delete;

   my $tag_list = $context->uri_for_action('tag/list');

   $context->stash( redirect $tag_list, ['Tag [_1] deleted', $name] );
   return;
}

sub edit {
   my ($self, $context, $tagid) = @_;

   my $tag     = $context->stash('tag');
   my $options = { context => $context, item => $tag, title => 'Edit tag' };
   my $form    = $self->form->new_with_context('Tag', $options);

   if ($form->process( posted => $context->posted )) {
      my $tag_view = $context->uri_for_action('tag/view', [$tagid]);
      my $message  = ['Tag [_1] updated', $form->item->name];

      $context->stash( redirect $tag_view, $message );
      return;
   }

   $context->stash( form => $form );
   return;
}

sub list {
   my ($self, $context) = @_;

   my $options = { context => $context, resultset => $context->model('Tag') };

   $context->stash( table => $self->table->new_with_context('Tag', $options) );
   return;
}

sub remove {
   my ($self, $context) = @_;

   return unless $self->has_valid_token($context);

   my $value = $context->request->body_parameters->{data} or return;
   my $rs    = $context->model('Tag');
   my $count = 0;

   for my $tag (grep { $_ } map { $rs->find($_) } @{$value->{selector}}) {
      $tag->delete;
      $count++;
   }

   $context->stash( response => { message => '${count} tag(s) deleted' });
   return;
}

sub view {
   my ($self, $context, $tagid) = @_;

   return;
}

use namespace::autoclean;

1;
