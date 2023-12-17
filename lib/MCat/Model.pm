package MCat::Model;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE NUL TRUE );
use HTTP::Status           qw( HTTP_OK );
use HTML::Forms::Types     qw( HashRef LoadableClass );
use HTML::Forms::Util      qw( verify_token );
use MCat::Util             qw( formpost redirect2referer );
use Ref::Util              qw( is_arrayref );
use Scalar::Util           qw( blessed weaken );
use Type::Utils            qw( class_type );
use Unexpected::Functions  qw( exception throw BadToken NoMethod );
use HTML::Forms::Manager;
use HTML::StateTable::Manager;
use MCat::Context;
use MCat::Navigation;
use Moo;
use MCat::Navigation::Attributes; # Will do namespace cleaning

with 'MCat::Role::Authorisation';
with 'MCat::Role::Schema';

has 'controllers' => is => 'ro', isa => HashRef, default => sub { {} };

has 'form' =>
   is      => 'lazy',
   isa     => class_type('HTML::Forms::Manager'),
   handles => { new_form => 'new_with_context' },
   default => sub {
      my $self     = shift;
      my $appclass = $self->config->appclass;

      return HTML::Forms::Manager->new({
         namespace => "${appclass}::Form", schema => $self->schema
      });
   };

has 'jobdaemon' =>
   is      => 'lazy',
   isa     => class_type('MCat::JobServer'),
   default => sub {
      my $self = shift;

      return $self->_jobdaemon_class->new(config => {
         appclass => $self->config->appclass,
         pathname => $self->config->bin->catfile('mcat-jobserver'),
      });
   };

has '_jobdaemon_class' =>
   is      => 'lazy',
   isa     => LoadableClass,
   coerce  => TRUE,
   default => 'MCat::JobServer';

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
         page_manager => $self->config->navigation_manager,
         view_name    => 'table',
      });
   };

has 'views' => is => 'ro', isa => HashRef, default => sub { {} };

# Public methods
sub allowed { # Allows all. Apply a role to modify this for permissions
   my ($self, $context, $moniker, $method) = @_;

   # Return false and stash a redirect to skip calling requested method
   return $method;
}

# Stash exception handler output to print an exception page
# Also called by component loader if model dies
sub error {
   my ($self, $context, $proto, $bindv, @args) = @_;

   my $exception;

   if (blessed $proto) { $exception = $proto }
   else {
      my $nav = $context->stash('nav');

      push @args, 'rv', HTTP_OK if $nav && $nav->is_script_request;

      $exception = exception $proto, $bindv // [], level => 2, @args;
   }

   $self->log->error($exception, $context);

   my $code = $exception->rv // 0;

   $context->stash(
      code      => $code > HTTP_OK ? $code : HTTP_OK,
      exception => $exception,
      page      => { %{$self->config->page}, layout => 'page/exception' },
   );

   $self->_finalise_stash($context);

   my $nav = $context->stash->{nav};

   $context->stash(redirect2referer $context, [$exception->original])
      if $nav && $nav->is_script_request;

   return;
}

sub execute { # Called by component loader for all model method calls
   my ($self, $context, $methods) = @_;

   my $stash = $context->stash;

   $stash->{method_chain} = $methods;

   my $last_method;

   for my $method (split m{ / }mx, $methods) {
      throw NoMethod, [ blessed $self, $method ] unless $self->can($method);

      $method = $self->allowed($context, $self->moniker, $method);

      $self->$method($context, @{$context->request->args}) if $method;

      return $stash->{response} if $stash->{response};

      $stash->{nav}->fix_status_for_fetch if exists $stash->{nav};

      return if $stash->{finalised} || exists $stash->{redirect};

      $last_method = $method;
   }

   $self->_finalise_stash($context, $last_method);
   return;
}

sub get_context { # Creates and returns a new context object from the request
   my ($self, $request, $models, $action) = @_;

   return MCat::Context->new(
      action      => $action,
      config      => $self->config,
      controllers => $self->controllers,
      forms       => $self->form,
      models      => $models,
      request     => $request,
      views       => $self->views
   );
}

sub root : Auth('none') {
   my ($self, $context) = @_;

   my $nav = MCat::Navigation->new({ context => $context, model => $self });

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
      $nav->item('page/register', []) if $self->config->registration;
   }

   $context->stash(nav => $nav);
   return;
}

sub verify_form_post { # Stash an exception if the CSRF token is bad
   my ($self, $context) = @_;

   my $token  = $context->get_body_parameters->{_verify};
   my $reason = verify_token $token, $context->session->serialise;

   return TRUE unless $reason;

   $self->error($context, BadToken, [$reason], level => 3);
   return FALSE;
}

# Private methods
sub _finalise_stash { # Add necessary defaults for the view to render
   my ($self, $context, $method) = @_;

   my $stash = $context->stash;

   $stash->{code} //= HTTP_OK unless exists $stash->{redirect};
   $stash->{finalised} = TRUE;
   $stash->{page} //= { %{$self->config->page} };
   $stash->{page}->{layout} //= $self->moniker . "/${method}";
   $stash->{version} = $MCat::VERSION;
   $stash->{view} //= $self->config->default_view;
   return;
}

1;
