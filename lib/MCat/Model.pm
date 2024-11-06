package MCat::Model;

use HTML::Forms::Constants qw( FALSE NUL TRUE );
use MCat::Util             qw( formpost );
use Type::Utils            qw( class_type );
use HTML::Forms::Manager;
use HTML::StateTable::Manager;
use Web::Components::Navigation;
use Moo;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'Web::Components::Model';
with    'MCat::Role::Authorisation';
with    'MCat::Role::Schema';

has '+context_class' => default => 'MCat::Context';

has 'form' =>
   is      => 'lazy',
   isa     => class_type('HTML::Forms::Manager'),
   handles => { new_form => 'new_with_context' },
   default => sub {
      my $self     = shift;
      my $appclass = $self->config->appclass;

      return HTML::Forms::Manager->new({
         namespace      => "${appclass}::Form",
         renderer_class => 'HTML::Forms::Render::EmptyDiv',
         schema         => $self->schema
      });
   };

has 'table' =>
   is      => 'lazy',
   isa     => class_type('HTML::StateTable::Manager'),
   handles => { new_table => 'new_with_context' },
   default => sub {
      my $self     = shift;
      my $appclass = $self->config->appclass;

      return HTML::StateTable::Manager->new({
         log          => $self->log,
         namespace    => "${appclass}::Table",
         page_manager => $self->config->wcom_resources->{navigation},
         view_name    => 'table',
      });
   };

# Public methods
sub root : Auth('none') {
   my ($self, $context) = @_;

   my $args = { context => $context, model => $self };
   my $nav  = Web::Components::Navigation->new($args);

   $nav->list('_control');

   my $session = $context->session;

   if ($session->authenticated) {
      $nav->item('page/changes');
      $nav->item('page/password', [$session->id]);
      $nav->item('user/profile', [$session->id]);
      $nav->item('user/totp', [$session->id]) if $session->enable_2fa;
      $nav->item(formpost, 'page/logout');
   }
   else {
      $nav->item('page/login');
      $nav->item('page/password', [$session->id]);
      $nav->item('page/register', []) if $self->config->registration;
   }

   $context->stash($self->navigation_key => $nav);
   return;
}

1;
