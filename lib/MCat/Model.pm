package MCat::Model;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE NUL TRUE );
use HTML::Forms::Types     qw( HashRef );
use HTML::Forms::Util      qw( verify_token );
use HTTP::Status           qw( HTTP_NOT_FOUND HTTP_OK );
use MCat::Util             qw( formpost maybe_render_partial );
use Ref::Util              qw( is_arrayref );
use Scalar::Util           qw( blessed weaken );
use Type::Utils            qw( class_type );
use Unexpected::Functions  qw( exception throw BadToken NoMethod );
use HTML::Forms::Manager;
use HTML::StateTable::Manager;
use MCat::Context;
use MCat::Navigation;
use MCat::Schema;
use Moo;
use MCat::Navigation::Attributes; # Will do namespace cleaning

with 'MCat::Role::Authorisation';

has 'controllers' => is => 'ro', isa => HashRef, default => sub { {} };

has 'form' =>
   is      => 'lazy',
   isa     => class_type('HTML::Forms::Manager'),
   builder => sub {
      my $self     = shift;
      my $appclass = $self->config->appclass;
      my $schema   = MCat::Schema->connect(@{$self->config->connect_info});
      my $options  = { namespace => "${appclass}::Form", schema => $schema };

      MCat::Schema->config($self->config) if MCat::Schema->can('config');

      return HTML::Forms::Manager->new($options);
   };

has 'table' =>
   is      => 'lazy',
   isa     => class_type('HTML::StateTable::Manager'),
   builder => sub {
      my $self     = shift;
      my $appclass = $self->config->appclass;
      my $options  = { namespace => "${appclass}::Table" };

      return HTML::StateTable::Manager->new($options);
   };

has 'views' => is => 'ro', isa => HashRef, default => sub { {} };

# Public methods
sub allowed { # Allows all. Apply a role to modify this for permissions
   my ($self, $context, $moniker, $method) = @_;

   # Return false and stash a redirect to skip calling requested method
   return $method;
}

sub error { # Stash exception handler output to print an exception page
   my ($self, $context, $class, $bindv, @args) = @_;

   my $exception;

   if (!blessed $class) {
      my $nav = $context->stash('nav');
      my $rv  = $nav && $nav->is_script_request ? HTTP_OK : HTTP_NOT_FOUND;

      $exception = exception $class, $bindv, level => 2, rv => $rv, @args;
   }
   else { $exception = $class }

   $self->exception_handler($context, $exception);
   return;
}

sub exception_handler { # Also called by component loader if model dies
   my ($self, $context, $exception) = @_;

   $self->log->error($exception);

   my $code = $exception->rv // 0;

   $context->stash(
      code      => $code > HTTP_OK ? $code : HTTP_OK,
      exception => $exception,
      page      => { %{$self->config->page}, layout => 'exception' },
   );
   $self->_finalise_stash($context);
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

      $self->_fix_fetch_redirect($context) if exists $stash->{redirect};

      return if $stash->{finalised} || exists $stash->{redirect};

      $last_method = $method;
   }

   $self->_finalise_stash($context, $last_method);
   return;
}

sub get_context { # Creates and returns a new context object from the request
   my ($self, $request, $models) = @_;

   return MCat::Context->new(
      config      => $self->config,
      controllers => $self->controllers,
      forms       => $self->form,
      models      => $models,
      request     => $request,
      views       => $self->views
   );
}

sub has_valid_token { # Stash an exception if the CSRF token is bad
   my ($self, $context) = @_;

   my $token  = $context->get_body_parameters->{_verify};
   my $reason = verify_token $token, $context->session->serialise;

   return TRUE unless $reason;

   $self->error($context, BadToken, [$reason], level => 3);
   return FALSE;
}

sub root : Auth('none') {
   my ($self, $context) = @_;

   my $session = $context->session;
   my $nav     = MCat::Navigation->new({ context => $context, model => $self });

   $nav->list('_control');

   if ($context->session->authenticated) {
      $nav->item('page/profile', [$session->id]);
      $nav->item('page/change_password', [$session->id]);
      $nav->item(formpost, 'page/logout');
   }
   else { $nav->item('page/login') }

   $context->stash(nav => $nav);
   return;
}

# Private methods
sub _finalise_stash { # Add necessary defaults for the view to render
   my ($self, $context, $method) = @_;

   my $stash = $context->stash;

   weaken $context;
   $stash->{code} //= HTTP_OK unless exists $stash->{redirect};
   $stash->{finalised} = TRUE;
   $stash->{page} //= { %{$self->config->page} };
   $stash->{page}->{layout} //= $self->moniker . "/${method}";
   $stash->{version} = $MCat::VERSION;
   $stash->{view} //= $self->config->default_view;
   maybe_render_partial $context;
   return;
}

sub _fix_fetch_redirect {
   my ($self, $context) = @_;

   my $nav = $context->stash('nav');

   return unless $nav && $nav->is_script_request;

   $context->stash->{code} = HTTP_OK;
   return;
}

1;
