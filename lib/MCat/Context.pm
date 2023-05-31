package MCat::Context;

use HTML::Forms::Constants qw( FALSE NUL STAR TRUE );
use HTML::Forms::Types     qw( ArrayRef Bool HashRef Str );
use HTML::Forms::Util      qw( get_token );
use List::Util             qw( pairs );
use Ref::Util              qw( is_arrayref is_hashref );
use Type::Utils            qw( class_type );
use MCat::Response;
use Moo;

with 'MCat::Role::Schema';

has 'action' => is => 'ro', isa => Str, predicate => 'has_action';

has 'api_routes' => is => 'lazy', isa => HashRef, default => sub {
   my $self = shift;

   return exists $self->models->{api} ? $self->models->{api}->routes : {};
};

has 'config' => is => 'ro', isa => class_type('MCat::Config'), required => TRUE;

has 'controllers' => is => 'ro', isa => HashRef, default => sub { {} };

has 'forms' => is => 'ro', isa => class_type('HTML::Forms::Manager'),
   weak_ref => TRUE;

has 'jobdaemon' => is => 'lazy', isa => class_type('App::Job::Daemon'),
   default => sub { shift->models->{job}->jobdaemon };

has 'models' => is => 'ro', isa => HashRef, default => sub { {} };

has 'posted' => is => 'lazy', isa => Bool,
   default => sub { lc shift->request->method eq 'post' ? TRUE : FALSE };

has 'request' =>
   is       => 'ro',
   isa      => class_type('Web::ComposableRequest::Base'),
   required => TRUE,
   weak_ref => TRUE;

has 'response' => is => 'ro', isa => class_type('MCat::Response'),
   default => sub { MCat::Response->new };

has 'session' => is => 'lazy', default => sub { shift->request->session };

has 'time_zone' => is => 'lazy', isa => Str,
   default => sub { shift->session->timezone };

has 'views' => is => 'ro', isa => HashRef, default => sub { {} };

has '_stash' => is => 'ro', isa => HashRef, default => sub {
   return { version => MCat->VERSION };
};

sub get_body_parameters {
   my $self = shift; return $self->forms->get_body_parameters($self);
}

sub model {
   my ($self, $rs_name) = @_; return $self->schema->resultset($rs_name);
}

sub res { shift->response }

sub stash {
   my ($self, @args) = @_;

   return $self->_stash unless $args[0];

   return $self->_stash->{$args[0]} unless $args[1];

   for my $pair (pairs @args) {
      $self->_stash->{$pair->key} = $pair->value;
   }

   return $self->_stash;
}

sub uri_for_action {
   my ($self, $action, $args, @params) = @_;

   my $uri    = $self->_action_path2uri($action) // $action;
   my $uris   = is_arrayref $uri ? $uri : [ $uri ];
   my $params = is_hashref $params[0] ? $params[0] : {@params};

   for my $candidate (@{$uris}) {
      my $n_stars =()= $candidate =~ m{ \* }gmx;

      if ($n_stars == 2 and $candidate =~ m{ / \* \* }mx) {
         ($uri = $candidate) =~ s{ / \* \* }{}mx;
         last;
      }

      next if $n_stars != 0 and $n_stars > scalar @{$args // []};

      $uri = $candidate;

      while ($uri =~ m{ \* }mx) {
         my $arg = shift @{$args // []};

         last unless defined $arg;

         $uri =~ s{ \* }{$arg}mx;
      }

      last;
   }

   $uri .= delete $params->{extension} if exists $params->{extension};

   return $self->request->uri_for($uri, $args, $params);
}

sub verification_token {
   my $self = shift;

   return get_token($self->config->token_lifetime, $self->session->serialise);
}

sub view {
   my ($self, $view) = @_; return $self->views->{$view};
}

# Private methods
sub _action_path2uri {
   my ($self, $action) = @_;

   return $self->api_routes->{$action} if exists $self->api_routes->{$action};

   for my $controller (keys %{$self->controllers}) {
      my $map = $self->controllers->{$controller}->action_path_map;

      return $map->{$action} if exists $map->{$action};
   }

   return;
}

use namespace::autoclean;

1;
