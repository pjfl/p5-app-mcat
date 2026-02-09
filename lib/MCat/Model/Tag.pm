package MCat::Model::Tag;

use HTML::Forms::Constants qw( EXCEPTION_CLASS );
use MCat::Util             qw( redirect );
use Unexpected::Functions  qw( UnknownTag Unspecified );
use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'tag';

sub base : Auth('admin') {
   my ($self, $context, $tagid) = @_;

   my $nav = $context->stash('nav')->list('tag')->item('tag/create');

   if ($tagid) {
      my $tag = $context->model('Tag')->find($tagid);

      return $self->error($context, UnknownTag, [$tagid]) unless $tag;

      $context->stash(tag => $tag);
      $nav->crud('tag', $tagid);
   }

   $nav->finalise;
   return;
}

sub create : Auth('admin') Nav('Create Tag') {
   my ($self, $context) = @_;

   my $form = $self->form->new_with_context('Tag', {
      context => $context, item_class => 'Tag', title => 'Create Tag'
   });

   if ($form->process( posted => $context->posted )) {
      my $tagid    = $form->item->id;
      my $tag_view = $context->uri_for_action('tag/view', [$tagid]);
      my $message  = ['Tag [_1] created', $form->item->name];

      $context->stash( redirect $tag_view, $message );
   }

   $context->stash( form => $form );
   return;
}

sub delete : Auth('admin') Nav('Delete Tag') {
   my ($self, $context, $tagid) = @_;

   return unless $self->verify_form_post($context);

   my $tag = $context->model('Tag')->find($tagid);

   return $self->error($context, UnknownTag, [$tagid]) unless $tag;

   my $name = $tag->name;

   $tag->delete;

   my $tag_list = $context->uri_for_action('tag/list');

   $context->stash( redirect $tag_list, ['Tag [_1] deleted', $name] );
   return;
}

sub edit : Auth('admin') Nav('Edit Tag') {
   my ($self, $context, $tagid) = @_;

   my $form = $self->form->new_with_context('Tag', {
      context => $context, item => $context->stash('tag'), title => 'Edit tag'
   });

   if ($form->process( posted => $context->posted )) {
      my $tag_view = $context->uri_for_action('tag/view', [$tagid]);
      my $message  = ['Tag [_1] updated', $form->item->name];

      $context->stash( redirect $tag_view, $message );
   }

   $context->stash( form => $form );
   return;
}

sub list : Auth('admin') Nav('Tags') {
   my ($self, $context) = @_;

   $context->stash(table => $self->table->new_with_context('Tag', {
      context => $context, resultset => $context->model('Tag')
   }));
   return;
}

sub remove : Auth('admin') {
   my ($self, $context) = @_;

   return unless $self->verify_form_post($context);

   my $value = $context->body_parameters->{data} or return;
   my $rs    = $context->model('Tag');
   my $count = 0;

   for my $tag (grep { $_ } map { $rs->find($_) } @{$value->{selector}}) {
      $tag->delete;
      $count++;
   }

   $context->stash(redirect2referer $context, ["${count} tag(s) deleted"]);
   return;
}

sub view : Auth('admin') Nav('View Tag') {
   my ($self, $context) = @_;

   my $tag     = $context->stash('tag');
   my $buttons = [{
      action    => $context->uri_for_action('tag/list'),
      classes   => 'left',
      method    => 'get',
      selection => 'disable_on_select',
      value     => 'List',
   },{
      action    => $context->uri_for_action('tag/edit', [$tag->id]),
      method    => 'get',
      selection => 'disable_on_select',
      value     => 'Edit',
   }];
   my $options = {
      caption      => 'View Tag',
      context      => $context,
      form_buttons => $buttons,
      result       => $tag,
   };

   $context->stash(table => $self->new_table('View::Object', $options));
   return;
}

1;
