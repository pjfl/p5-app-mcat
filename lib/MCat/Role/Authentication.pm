package MCat::Role::Authentication;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE TRUE );
use HTML::Forms::Types     qw( HashRef Object );
use Class::Usul::Cmd::Util qw( ensure_class_loaded );
use Unexpected::Functions  qw( throw Unspecified );
use Moo::Role;

requires qw( schema session );

has '_realms' => is => 'ro', isa => HashRef[Object], default => sub { {} };

sub authenticate {
   my ($self, $args, $realm) = @_;

   $args //= {};
   $args->{user} //= $self->find_user($args, $realm);

   return $self->_find_realm($realm)->authenticate($args);
}

sub find_user {
   my ($self, $args, $realm) = @_;

   $args //= {};
   $args->{session} = $self->session;

   return $self->_find_realm($realm)->find_user($args);
}

sub logout {
   my $self = shift;

   $self->session->authenticated(FALSE);
   return;
}

sub set_authenticated {
   my ($self, $args, $realm) = @_;

   $args //= {};
   $args->{user} //= $self->find_user($args, $realm);
   $args->{session} = $self->session;
   $self->session->authenticated(TRUE);

   return $self->_find_realm($realm)->to_session($args);
}

# Private methods
sub _find_realm {
   my ($self, $realm) = @_;

   my $config = $self->config->authentication;

   $realm //= $config->{default_realm};

   throw Unspecified, ['default_realm'] unless $realm;

   return $self->_realms->{$realm} if $self->_realms->{$realm};

   my $ns    = $config->{namespace} // 'MCat::Authentication::Realms::';
   my $class = $config->{classes}->{$realm} // ucfirst $realm;

   $class = ('+' eq substr $realm, 0, 1) ? substr $realm, 1 : $ns . $class;

   ensure_class_loaded $class;

   my $attr = {
      %{$config->{$realm} // {}}, realm => $realm, schema => $self->schema
   };

   return $self->_realms->{$realm} = $class->new($attr);
}

use namespace::autoclean;

1;
