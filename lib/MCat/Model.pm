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
         schema         => $self->schema,
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
         log       => $self->log,
         namespace => "${appclass}::Table",
         view_name => 'table',
      });
   };

# Public methods
sub root : Auth('none') {
   my ($self, $context) = @_;

   my $session = $context->session;
   my $actions = $self->config->default_actions;
   my $nav     = Web::Components::Navigation->new({
      context       => $context,
      footer_action => $actions->{footer},
      logger_action => $actions->{logger},
      model         => $self,
   });

   $nav->list('bugs')->item('bug/create');
   $nav->list('_control');

   if ($session->authenticated) {
      $nav->menu('bugs')->item('bug/list');
      $nav->item($actions->{changes}) if $actions->{changes};
      $nav->item($actions->{password}, [$session->id]);
      $nav->item($actions->{profile}, [$session->id]);
      $nav->item($actions->{totp}, [$session->id]) if $session->enable_2fa;
      $nav->item(formpost, $actions->{logout});
   }
   else {
      $nav->item($actions->{password}, [$session->id]);
      $nav->item($actions->{login});
      $nav->item($actions->{register}, []) if $self->config->registration;
   }

   $context->stash($self->navigation_key => $nav);
   return;
}

1;
