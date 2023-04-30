package MCat::Model::User;

use HTML::Forms::Constants qw( EXCEPTION_CLASS );
use MCat::Util             qw( redirect redirect2referer );
use Unexpected::Functions  qw( UnknownUser Unspecified );
use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'user';

sub base : Auth('view') {
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
   my $form    = $self->new_form('User', $options);

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

   my $form = $self->new_form('User', {
      context => $context, item => $context->stash('user'), title => 'Edit User'
   });

   if ($form->process( posted => $context->posted )) {
      my $user_view = $context->uri_for_action('user/view', [$userid]);
      my $message  = ['User [_1] updated', $form->item->name];

      $context->stash( redirect $user_view, $message );
   }

   $context->stash( form => $form );
   return;
}

sub profile : Auth('view') Nav('Profile') {
   my ($self, $context, $userid) = @_;

   my $options = { context => $context, user => $context->stash('user') };
   my $form    = $self->new_form('Profile', $options);

   if ($form->process( posted => $context->posted )) {
      my $name    = $form->user->name;
      my $default = $context->uri_for_action($self->config->redirect);
      my $message = ['User [_1] profile updated', $name];

      $context->stash( redirect $default, $message );
   }

   $context->stash( form => $form );
   return;
}

sub list : Auth('admin') Nav('Users') {
   my ($self, $context) = @_;

   my $options = { context => $context, resultset => $context->model('User') };

   $context->stash(table => $self->new_table('User', $options));
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

   $context->stash(redirect2referer $context, ["${count} tag(s) deleted"]);
   return;
}

sub view : Auth('admin') Nav('View User') {
   my ($self, $context, $userid) = @_;

   $context->stash(table => $self->new_table('User::View', {
      caption => 'User View',
      context => $context,
      result  => $context->stash('user')
   }));
   return;
}

1;
