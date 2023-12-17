package MCat::Model::List;

use HTML::Forms::Constants qw( EXCEPTION_CLASS );
use MCat::Util             qw( redirect );
use Unexpected::Functions  qw( UnknownList Unspecified );
use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'list';

sub base {
   my ($self, $context, $listid) = @_;

   my $nav = $context->stash('nav')->list('list')->item('list/create');

   if ($listid) {
      my $list = $context->model('List')->find($listid);

      return $self->error($context, UnknownList, [$listid]) unless $list;

      $context->stash( list => $list );
      $nav->crud('list', $listid);
   }

   $nav->finalise;
   return;
}

sub create : Nav('Create List') {
   my ($self, $context) = @_;

   my $options = { context => $context, title => 'Create List' };
   my $form    = $self->new_form('List', $options);

   if ($form->process( posted => $context->posted )) {
      my $listid    = $form->item->id;
      my $list_view = $context->uri_for_action('list/view', [$listid]);
      my $message   = ['List [_1] created', $form->item->name];

      $context->stash( redirect $list_view, $message );
   }

   $context->stash( form => $form );
   return;
}

sub delete : Nav('Delete List') {
   my ($self, $context, $listid) = @_;

   return unless $self->verify_form_post($context);

   my $list = $context->model('List')->find($listid);

   return $self->error($context, UnknownList, [$listid]) unless $list;

   my $name = $list->name;

   $list->delete;

   my $list_list = $context->uri_for_action('list/list');

   $context->stash( redirect $list_list, ['List [_1] deleted', $name] );
   return;
}

sub edit : Nav('Edit List') {
   my ($self, $context, $listid) = @_;

   my $form = $self->new_form('List', {
      context => $context,
      item    => $context->stash('list'),
      title   => 'Edit List'
   });

   if ($form->process( posted => $context->posted )) {
      my $list_view = $context->uri_for_action('list/view', [$listid]);
      my $message   = ['List [_1] updated', $form->item->name];

      $context->stash( redirect $list_view, $message );
   }

   $context->stash( form => $form );
   return;
}

sub list : Nav('Lists') {
   my ($self, $context) = @_;

   $context->stash(table => $self->new_table('List', { context => $context }));
   return;
}

sub view : Nav('View List') {
   my ($self, $context, $listid) = @_;

   $context->stash(table => $self->new_table('Object::View', {
      caption => 'List View',
      context => $context,
      result  => $context->stash('list')
   }));
   return;
}

1;
