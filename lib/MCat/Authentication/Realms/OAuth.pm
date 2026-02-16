package MCat::Authentication::Realms::OAuth;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE NUL TRUE );
use HTML::Forms::Types     qw( CodeRef HashRef );
use MCat::Util             qw( create_token new_uri );
use Type::Utils            qw( class_type );
use Unexpected::Functions  qw( throw RedirectToAuth UnauthorisedAccess
                               UnknownToken Unspecified );
use HTTP::Tiny;
use Moo;

extends 'MCat::Authentication::Realms::DBIC';
with    'MCat::Role::Redis';

has '+redis_client_name' => is => 'ro', default => 'notification';

has 'config' =>
   is       => 'ro',
   isa      => class_type('MCat::Config'),
   required => TRUE;

has 'providers' =>
   is      => 'ro',
   isa     => HashRef,
   default => sub { {} };

has 'uri_for_action' => is => 'ro', isa => CodeRef, required => TRUE;

has '_ua' =>
   is      => 'lazy',
   isa     => class_type('HTTP::Tiny'),
   default => sub { HTTP::Tiny->new };

sub authenticate {
   my ($self, $args) = @_;

   my $user = $args->{user};

   throw Unspecified, ['user'] unless $user;

   $self->_get_oauth_request_token($user) unless $args->{state};

   throw UnauthorisedAccess unless $args->{code};

   my $method = $self->validate_ip_method;

   $user->$method($args->{address}) if $args->{address} && $user->can($method);

   # TODO: Consider what next?
   # Use request token ($args->{code}), get access token
   # But to what end. What protected resources might we want?
   warn('Redis key ' . $args->{state} . "\n");
   warn('Request token ' . $args->{code} . "\n");
   return TRUE;
}

sub find_user {
   my ($self, $args) = @_;

   if (my $token = $args->{state}) {
      my $key     = "oauth-${token}";
      my $user_id = $self->redis_client->get($key);

      throw UnknownToken, [$token] unless $user_id;

      $self->redis_client->del($key);
      $args->{username} = $user_id;
   }

   return $self->next::method($args);
}

# Private methods
sub _get_oauth_request_token {
   my ($self, $user) = @_;

   my ($domain) = reverse split m{ @ }mx, $user->email;
   my $provider = $self->providers->{$domain};

   throw 'OAuth Provider [_1] unknown', [$domain] unless $provider;

   my $token = create_token;
   my $key   = "oauth-${token}";

   $self->redis_client->set($key, $user->id);
   $self->redis_client->expire($key, 180);

   my $nonce  = substr create_token, 0, 12;
   my $cb_url = $self->uri_for_action->('misc/oauth');
   my $params = {
      client_id     => $provider->{client_id},
      nonce         => $nonce,
      redirect_uri  => $cb_url->as_string,
      response_type => 'code',
      scope         => 'openid email',
      state         => $token,
   };
   my $query  = $self->_ua->www_form_urlencode($params);
   my $uri    = new_uri 'https', $provider->{request_url}."?${query}" ;

   throw RedirectToAuth, [$uri];
}

use namespace::autoclean;

1;
