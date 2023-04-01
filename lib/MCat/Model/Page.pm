package MCat::Model::Page;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE NUL TRUE );
use MCat::Util             qw( new_uri redirect );
use Unexpected::Functions  qw( PageNotFound UnknownUser );
use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'page';

sub base : Auth('none') {
   my ($self, $context, $userid) = @_;

   if ($userid) {
      my $user = $context->model('User')->find($userid);

      $context->stash( user => $user );
   }

   $context->stash('nav')->finalise;
   return;
}

sub access_denied : Auth('none') {}

sub change_password : Nav('Change Password') Auth('none') {
   my ($self, $context, $userid) = @_;

   my $form = $self->form->new_with_context('ChangePassword', {
      context => $context, item => $context->stash('user')
   });

   if ($form->process( posted => $context->posted )) {
      my $name    = $form->item->name;
      my $default = $context->uri_for_action('artist/list');
      my $message = ['User [_1] changed password', $name];

      $context->stash( redirect $default, $message );
   }

   $context->stash( form => $form );
   return;
}

sub login : Nav('Login') Auth('none') {
   my ($self, $context) = @_;

   my $form = $self->form->new_with_context('Login', {
      context => $context, log => $self->log
   });

   if ($form->process( posted => $context->posted )) {
      my $name    = $form->field('name')->value;
      my $user    = $context->model('User')->find({ name => $name })
         or return $self->error($context, UnknownUser, [$name]);
      my $default = $context->uri_for_action('artist/list');
      my $message = ['User [_1] logged in', $name];
      my $session = $context->session;

      $session->id($user->id);
      $session->authenticated(TRUE);
      $session->role($user->role->name);
      $session->username($name);
      $context->stash( redirect $default, $message );
   }

   $context->stash( form => $form );
   return;
}

sub logout : Nav('Logout') Auth('view') {
   my ($self, $context) = @_;

   return unless $self->has_valid_token($context);

   my $default = $context->uri_for_action('page/login');
   my $message = ['User [_1] logged out', $context->session->username];
   my $session = $context->session;

   $session->authenticated(FALSE);
   $session->role(NUL);
   $context->stash( redirect $default, $message );
   return;
}

sub not_found : Auth('none') {
   my ($self, $context) = @_;

   return $self->error($context, PageNotFound, [$context->request->path]);
}

1;
