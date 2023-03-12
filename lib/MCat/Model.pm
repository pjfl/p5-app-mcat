package MCat::Model;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE NUL TRUE );
use HTML::Forms::Types     qw( HashRef );
use HTML::Forms::Util      qw( verify_token );
use HTTP::Status           qw( HTTP_OK );
use Ref::Util              qw( is_arrayref );
use Scalar::Util           qw( blessed weaken );
use Type::Utils            qw( class_type );
use Unexpected::Functions  qw( exception throw BadToken NoMethod );
use HTML::Forms::Manager;
use HTML::StateTable::Manager;
use MCat::Context;
use MCat::Schema;
use Moo;

has 'form' =>
   is      => 'lazy',
   isa     => class_type('HTML::Forms::Manager'),
   builder => sub {
      my $self     = shift;
      my $appclass = $self->config->appclass;
      my $schema   = MCat::Schema->connect(@{$self->config->connect_info});
      my $options  = { namespace => "${appclass}::Form", schema => $schema };

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
   my ($self, $context, $method) = @_;

   # Return false and stash a redirect to skip calling requested method
   return $method;
}

sub error { # Stash exception handler output to print an exception page
   my ($self, $context, $class, @args) = @_;

   my $exception;

   if (blessed $class) { $exception = $class }
   else {
      my $bindv = shift @args;

      $exception = exception $class, $bindv, level => 2, @args;
   }

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
      template  => { layout => 'exception' },
   );
   $self->_finalise_stash($context);
   return;
}

sub execute { # Called by component loader for all model method calls
   my ($self, $context, $method) = @_;

   throw NoMethod, [ blessed $self, $method ] unless $self->can($method);

   $method = $self->allowed($context, $method);

   $self->$method($context, @{$context->request->args}) if $method;

   return $context->stash->{response} if $context->stash->{response};

   $self->_finalise_stash($context, $method)
      unless $context->stash->{finalised};
   return;
}

sub get_context { # Creates and returns a new context object from the request
   my ($self, $request, $models) = @_;

   return MCat::Context->new(
      config  => $self->config,
      models  => $models,
      request => $request,
      views   => $self->views
   );
}

sub has_valid_token { # Stash an exception if the CSRF token is bad
   my ($self, $context) = @_;

   my $token = $self->form->get_body_parameters($context)->{_verify};

   return TRUE if verify_token $context->session->serialise, $token;

   $self->error($context, BadToken, level => 3);
   return FALSE;
}

# Private methods
sub _finalise_stash { # Add necessary defaults for the view to render
   my ($self, $context, $method) = @_;

   my $stash = $context->stash;

   weaken $context;
   $stash->{code} //= HTTP_OK unless exists $stash->{redirect};
   $stash->{context} = $context;
   $stash->{finalised} = TRUE;
   $stash->{template} //= {};
   $stash->{template}->{layout} //= $self->moniker . "/${method}";
   $stash->{view} //= $self->config->default_view;
   return;
}

use namespace::autoclean;

1;
