package MCat::Model::Tag;

use HTML::Forms::Constants qw( EXCEPTION_CLASS );
use MCat::Util             qw( redirect register_action_paths );
use Unexpected::Functions  qw( UnknownTag Unspecified );
use Web::Simple;

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'tag';

register_action_paths 'tag', {
   create => 'tag/create',
   delete => 'tag/*/delete',
   edit   => 'tag/*/edit',
   list   => 'tag',
   view   => 'tag/*',
};

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

   return $self->error($context, Unspecified, ['tagid']) unless $tagid;

   my $tag = $context->model('Tag')->find($tagid);

   return $self->error($context, UnknownTag, [$tagid]) unless $tag;

   my $name = $tag->name;

   $tag->delete;

   my $tag_list = $context->uri_for_action('tag/list');

   $context->stash( redirect $tag_list, ['Tag [_1] deleted', $name] );
   return;
}

sub edit {
   my ($self, $context, $tagid) = @_;

   return $self->error($context, Unspecified, ['tagid']) unless $tagid;

   my $tag = $context->model('Tag')->find($tagid);

   return $self->error($context, UnknownTag, [$tagid]) unless $tag;

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

   my $value = $context->request->body_parameters->{data} or return;

   for my $tagid (@{$value->{selector}}) {
      $self->delete($context, $tagid);
      delete $context->stash->{redirect};
   }

   $context->stash( response => { message => 'Tags deleted' });
   return;
}

sub view {
   my ($self, $context, $tagid) = @_;

   return $self->error($context, Unspecified, ['tagid']) unless $tagid;

   my $tag = $context->model('Tag')->find($tagid);

   return $self->error($context, UnknownTag, [$tagid]) unless $tag;

   $context->stash(tag => $tag);
   return;
}

use namespace::autoclean;

1;
