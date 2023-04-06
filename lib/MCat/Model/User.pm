package MCat::Model::User;

use HTML::Forms::Constants qw( EXCEPTION_CLASS );
use MCat::Util             qw( redirect );
use Unexpected::Functions  qw( UnknownUser Unspecified );
use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'user';

sub base : Auth('admin') {
   my ($self, $context, $userid) = @_;

   my $nav = $context->stash('nav')->list('user')->item('user/create');

   if ($userid) {
      my $user = $context->model('User')->find($userid);

      return $self->error($context, UnknownUser, [$userid]) unless $user;

      $context->stash(user => $user);
      $nav->crud('user', $userid);
   }

   $nav->finalise;
   return;
}

sub create : Auth('admin') Nav('Create User') {
   my ($self, $context) = @_;

   my $options = { context => $context, title => 'Create User' };
   my $form    = $self->form->new_with_context('User', $options);

   if ($form->process( posted => $context->posted )) {
      my $userid    = $form->item->id;
      my $user_view = $context->uri_for_action('user/view', [$userid]);
      my $message   = ['User [_1] created', $form->item->name];

      $context->stash( redirect $user_view, $message );
   }

   $context->stash( form => $form );
   return;
}

sub delete : Auth('admin') Nav('Delete User') {
   my ($self, $context, $userid) = @_;

   return unless $self->has_valid_token($context);

   my $user = $context->model('User')->find($userid);

   return $self->error($context, UnknownUser, [$userid]) unless $user;

   my $name = $user->name;

   $user->delete;

   my $user_list = $context->uri_for_action('user/list');

   $context->stash( redirect $user_list, ['User [_1] deleted', $name] );
   return;
}

sub edit : Auth('admin') Nav('Edit User') {
   my ($self, $context, $userid) = @_;

   my $form = $self->form->new_with_context('User', {
      context => $context, item => $context->stash('user'), title => 'Edit user'
   });

   if ($form->process( posted => $context->posted )) {
      my $user_view = $context->uri_for_action('user/view', [$userid]);
      my $message  = ['User [_1] updated', $form->item->name];

      $context->stash( redirect $user_view, $message );
   }

   $context->stash( form => $form );
   return;
}

sub list : Auth('admin') Nav('Users') {
   my ($self, $context) = @_;

   $context->stash(table => $self->table->new_with_context('User', {
      context => $context, resultset => $context->model('User')
   }));
   return;
}

sub remove : Auth('admin') {
   my ($self, $context) = @_;

   return unless $self->has_valid_token($context);

   my $value = $context->request->body_parameters->{data} or return;
   my $rs    = $context->model('User');
   my $count = 0;

   for my $user (grep { $_ } map { $rs->find($_) } @{$value->{selector}}) {
      $user->delete;
      $count++;
   }

   $context->stash( response => { message => '${count} user(s) deleted' });
   return;
}

sub view : Auth('admin') Nav('View User') {
   my ($self, $context, $userid) = @_;

   $context->stash(table => $self->table->new_with_context('Object::View', {
      context => $context, result => $context->stash('user')
   }));
   return;
}

1;
