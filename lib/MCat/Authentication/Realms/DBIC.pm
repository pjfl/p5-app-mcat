package MCat::Authentication::Realms::DBIC;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE TRUE );
use HTML::Forms::Types     qw( Str );
use Scalar::Util           qw( blessed );
use Type::Utils            qw( class_type );
use Unexpected::Functions  qw( throw Unspecified );
use Moo;

has 'authenticate_method' => is => 'ro', isa => Str, default => 'authenticate';

has 'find_user_method' => is => 'ro', isa => Str, default => 'find_by_key';

has 'realm' => is => 'ro', isa => Str, required => TRUE;

has 'result_class' => is => 'ro', isa => Str, default => 'User';

has 'schema' =>
   is       => 'ro',
   isa      => class_type('DBIx::Class::Schema'),
   required => TRUE;

sub authenticate {
   my ($self, $args) = @_;

   throw Unspecified, ['user'] unless $args->{user};

   my $method = $self->authenticate_method;

   return $args->{user}->$method($args->{password}, $args->{code});
}

sub find_user {
   my ($self, $args) = @_;

   my $rs     = $self->schema->resultset($self->result_class);
   my $method = $self->find_user_method;

   return $rs->$method($args->{username}, $args->{options});
}

sub to_session {
   my ($self, $args) = @_;

   my $session = $args->{session};

   return unless $session && blessed $session;

   $session->realm($self->realm) if $session->can('realm');

   my $user    = $args->{user} or return;
   my $profile = $user->profile_value;

   for my $key (grep { $_ ne 'authenticated' } keys %{$profile}) {
      my $value       = $profile->{$key};
      my $value_class = blessed $value;

      if ($value_class && $value_class eq 'JSON::PP::Boolean') {
         $value = "${value}" ? TRUE : FALSE;
      }

      $session->$key($value) if defined $value && $session->can($key);
   }

   $session->email($user->email)     if $session->can('email');
   $session->id($user->id)           if $session->can('id');
   $session->role($user->role->name) if $session->can('role');
   $session->username($user->name)   if $session->can('username');
   return;
}

use namespace::autoclean;

1;
