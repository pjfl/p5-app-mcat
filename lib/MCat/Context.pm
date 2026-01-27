package MCat::Context;

use attributes ();

use Class::Usul::Cmd::Constants qw( EXCEPTION_CLASS FALSE NUL TRUE );
use Unexpected::Types           qw( ArrayRef Bool HashRef Int Str );
use HTML::Forms::Util           qw( get_token verify_token );
use List::Util                  qw( pairs );
use Ref::Util                   qw( is_arrayref is_coderef is_hashref );
use Scalar::Util                qw( blessed );
use Type::Utils                 qw( class_type );
use Unexpected::Functions       qw( throw NoMethod UnknownModel );
use MCat::Response;
use Moo;

with 'MCat::Role::Schema';

has 'action' => is => 'rw', isa => Str, predicate => 'has_action';

has 'config' => is => 'ro', isa => class_type('MCat::Config'), required => TRUE;

has 'controllers' => is => 'ro', isa => HashRef, default => sub { {} };

has 'icons_uri' =>
   is      => 'lazy',
   isa     => class_type('URI'),
   default => sub {
      my $self = shift;

      return $self->request->uri_for($self->config->icons);
   };

has 'models' => is => 'ro', isa => HashRef, default => sub { {} };

has 'posted' =>
   is      => 'lazy',
   isa     => Bool,
   default => sub { lc shift->request->method eq 'post' ? TRUE : FALSE };

has 'request' =>
   is       => 'ro',
   isa      => class_type('Web::ComposableRequest::Base'),
   required => TRUE,
   weak_ref => TRUE;

has 'response' =>
   is      => 'ro',
   isa     => class_type('MCat::Response'),
   default => sub { MCat::Response->new };

has 'session' => is => 'lazy', default => sub { shift->request->session };

has 'time_zone' =>
   is      => 'lazy',
   isa     => Str,
   default => sub { shift->session->timezone };

has 'token_lifetime' =>
   is      => 'lazy',
   isa     => Int,
   default => sub { shift->config->token_lifetime };

has 'views' => is => 'ro', isa => HashRef, default => sub { {} };

has '_stash' =>
   is      => 'lazy',
   isa     => HashRef,
   default => sub {
      my $self   = shift;
      my $config = $self->config;
      my $prefix = $config->prefix;
      my $skin   = $self->session->skin || $config->skin;

      return {
         chartlibrary       => 'js/highcharts.js',
         favicon            => 'img/favicon.ico',
         features           => $self->session->features,
         javascript         => "js/${prefix}.js",
         session_updated    => $self->session->updated,
         skin               => $skin,
         stylesheet         => "css/${prefix}-${skin}.css",
         theme              => $self->session->theme,
         verification_token => $self->verification_token,
         version            => MCat->VERSION,
      };
   };

with 'MCat::Role::Authentication';

sub button_pressed {
   return shift->request->body_parameters->{_submit} // FALSE;
}

sub clear_redirect {
   return delete shift->stash->{redirect};
}

sub endpoint {
   return (split m{ / }mx, shift->stash('method_chain'))[-1];
}

sub get_attributes {
   my ($self, $action) = @_;

   return unless $action;

   return attributes::get($action) // {} if is_coderef $action;

   my ($moniker, $method) = split m{ / }mx, $action;

   return {} unless $moniker && $method;

   my $component = $self->models->{$moniker}
      or throw UnknownModel, [$moniker];
   my $coderef = $component->can($method)
      or throw NoMethod, [blessed $component, $method];

   return attributes::get($coderef) // {};
}

sub get_body_parameters {
   my $self    = shift;
   my $request = $self->request;

   return { %{$request->body_parameters->mixed // {}} }
      if $request->isa('Plack::Request');

   return { %{$request->body_parameters // {}} }
      if $request->isa('Catalyst::Request')
      || $request->isa('Web::ComposableRequest::Base');

   return $request->parameters if $request->can('parameters');

   return {};
}

sub model {
   my ($self, $rs_name) = @_;

   return $rs_name ? $self->schema->resultset($rs_name) : undef;
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

      if ($n_stars == 2 and $candidate =~ m{ / \* \. \* }mx) {
         ($uri = $candidate) =~ s{ / \* \. \* }{}mx;
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

   return get_token $self->config->token_lifetime, $self->session->serialise;
}

sub verify_form_post {
   my $self  = shift;
   my $token = $self->get_body_parameters->{_verify};

   return verify_token $token, $self->session->serialise;
}

sub view {
   my ($self, $view) = @_; return $self->views->{$view};
}

# Private methods
sub _action_path2uri {
   my ($self, $action) = @_;

   for my $controller (keys %{$self->controllers}) {
      my $map = $self->controllers->{$controller}->action_path_map;

      return $map->{$action} if exists $map->{$action};
   }

   return;
}

use namespace::autoclean;

1;
