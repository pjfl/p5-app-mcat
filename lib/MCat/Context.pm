package MCat::Context;

use HTML::Forms::Constants qw( FALSE NUL STAR TRUE );
use HTML::Forms::Types     qw( ArrayRef Bool HashRef Str );
use HTML::Forms::Util      qw( get_token );
use List::Util             qw( pairs );
use MCat::Util             qw( action_path2uri );
use Ref::Util              qw( is_arrayref is_hashref );
use Type::Utils            qw( class_type );
use MCat::Response;
use MCat::Schema;
use Moo;

has 'config', is => 'ro', isa => class_type('MCat::Config'), required => TRUE;

has 'messages' => is => 'lazy', isa => ArrayRef, builder => sub {
   my $self = shift;

   return $self->session->collect_status_messages($self->request);
};

has 'models' => is => 'ro', isa => HashRef, weak_ref => TRUE,
   default => sub { {} };

has 'posted' => is => 'lazy', isa => Bool,
   builder => sub { lc shift->request->method eq 'post' ? TRUE : FALSE };

has 'request' =>
   is       => 'ro',
   isa      => class_type('Web::ComposableRequest::Base'),
   required => TRUE;

has 'response' => is => 'ro', isa => class_type('MCat::Response'),
   builder => sub { MCat::Response->new };

has 'session' => is => 'lazy', builder => sub { shift->request->session };

has 'schema'  => is => 'lazy', isa => class_type('MCat::Schema'),
   builder => sub { MCat::Schema->connect(@{shift->config->connect_info}) };

has 'table_action_url' => is => 'lazy', isa => class_type('URI'),
   builder => sub { shift->uri_for_action('api/table_action') };

has 'table_preference_url' => is => 'lazy', isa => class_type('URI'),
   builder => sub { shift->uri_for_action('api/table_preference') };

has 'views' => is => 'ro', isa => HashRef, default => sub { {} };

has '_stash' => is => 'ro', isa => HashRef, default => sub { {} };

sub model {
   my ($self, $rs_name) = @_; return $self->schema->resultset($rs_name);
}

sub preference { # Accessor/mutator with builtin clearer. Store "" to delete
   my ($self, $name, $value) = @_;

   return unless $name;

   my $rs = $self->model('Preference');

   return $rs->update_or_create( # Mutator
      { name => $name, value => $value }, { key => 'preference_name' }
   ) if $value && $value ne '""';

   my $pref = $rs->find({ name => $name }, { key => 'preference_name' });

   return $pref->delete if defined $pref && defined $value; # Clearer

   return $pref; # Accessor
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

   my $uri    = action_path2uri($action) // $action;
   my $uris   = is_arrayref $uri ? $uri : [ $uri ];
   my $params = is_hashref $params[0] ? $params[0] : {@params};

   for my $candidate (@{$uris}) {
      my $n_stars =()= $candidate =~ m{ \* }gmx;

      next if $n_stars != 0 and $n_stars > scalar @{$args // []};

      while ($candidate =~ m{ \* }mx) {
         my $arg = shift @{$args // []};

         last unless defined $arg;

         $candidate =~ s{ \* }{$arg}mx;
      }

      while (my $arg = shift @{$args // []}) { $candidate .= "/${arg}" }

      $uri = $candidate;
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

use namespace::autoclean;

1;
