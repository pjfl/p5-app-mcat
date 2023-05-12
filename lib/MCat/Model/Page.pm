package MCat::Model::Page;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE NUL TRUE );
use HTTP::Status           qw( HTTP_OK );
use JSON::MaybeXS          qw( encode_json );
use MCat::Util             qw( new_uri redirect );
use Unexpected::Functions  qw( PageNotFound UnknownUser );
use Try::Tiny;
use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'page';

sub base : Auth('none') {
   my ($self, $context, $userid) = @_;

   if ($userid) {
      my $user = $context->model('User')->find($userid)
         or return $self->error($context, UnknownUser, [$userid]);

      $context->stash( user => $user );
   }

   $context->stash('nav')->finalise;
   return;
}

sub access_denied : Auth('none') {}

sub default : Auth('none') {
   my ($self, $context) = @_;

   my $default = $context->uri_for_action($self->config->default_route);

   $context->stash( redirect $default, []);
   return;
}

sub has_property : Auth('none') {
   my ($self, $context) = @_;

   my $req   = $context->request;
   my $class = $req->query_params->('class');
   my $prop  = $req->query_params->('property');
   my $value = $req->query_params->('value', { raw => TRUE });
   my $body  = { found => \1 };

   if ($value) {
      try { # Defensively written
         my $r = $context->model($class)->find_by_key($value);

         $body->{found} = \0 unless $r && $r->execute($prop);
      }
      catch { $self->log->error($_, $context) };
   }

   $context->stash(body => encode_json($body), code => HTTP_OK, view => 'json');
   return;
}

sub login : Auth('none') Nav('Login') {
   my ($self, $context) = @_;

   my $options = { context => $context, log => $self->log };
   my $form    = $self->form->new_with_context('Login', $options);

   if ($form->process( posted => $context->posted )) {
      my $name     = $form->field('name')->value;
      my $default  = $context->uri_for_action($self->config->redirect);
      my $wanted   = $context->session->wanted;
      my $location = new_uri $context->request->scheme, $wanted if $wanted;
      my $message  = ['User [_1] logged in', $name];

      $context->stash( redirect $location || $default, $message );
      $context->session->wanted(NUL);
   }

   $context->stash( form => $form );
   return;
}

sub logout : Auth('view') Nav('Logout') {
   my ($self, $context) = @_;

   return unless $self->has_valid_token($context);

   my $default = $context->uri_for_action('page/login');
   my $message = ['User [_1] logged out', $context->session->username];
   my $session = $context->session;

   $session->authenticated(FALSE);
   $session->role(NUL);
   $session->wanted(NUL);
   $context->stash( redirect $default, $message );
   return;
}

sub not_found : Auth('none') {
   my ($self, $context) = @_;

   return $self->error($context, PageNotFound, [$context->request->path]);
}

sub password : Auth('none') Nav('Change Password') {
   my ($self, $context, $userid) = @_;

   my $form = $self->form->new_with_context('ChangePassword', {
      context => $context, item => $context->stash('user'), log => $self->log
   });

   if ($form->process( posted => $context->posted )) {
      my $name    = $form->item->name;
      my $default = $context->uri_for_action($self->config->redirect);
      my $message = ['User [_1] changed password', $name];

      $context->stash( redirect $default, $message );
   }

   $context->stash( form => $form );
   return;
}

1;
