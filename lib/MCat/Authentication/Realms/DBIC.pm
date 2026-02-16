package MCat::Authentication::Realms::DBIC;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE TRUE );
use HTML::Forms::Types     qw( Str );
use Scalar::Util           qw( blessed );
use Type::Utils            qw( class_type );
use Unexpected::Functions  qw( throw Unspecified );
use Moo;

with 'MCat::Role::UpdatingSession';

has 'authenticate_method' => is => 'ro', isa => Str, default => 'authenticate';

has 'find_user_method' => is => 'ro', isa => Str, default => 'find_by_key';

has 'realm' => is => 'ro', isa => Str, required => TRUE;

has 'result_class' => is => 'ro', isa => Str, default => 'User';

has 'schema' =>
   is       => 'ro',
   isa      => class_type('DBIx::Class::Schema'),
   required => TRUE;

has 'validate_ip_method' =>
   is      => 'ro',
   isa     => Str,
   default => 'validate_address';

sub authenticate {
   my ($self, $args) = @_;

   throw Unspecified, ['user'] unless $args->{user};

   my $user   = $args->{user};
   my $method = $self->validate_ip_method;

   $user->$method($args->{address}) if $args->{address} && $user->can($method);

   $method = $self->authenticate_method;
   $user->$method($args->{password}, $args->{code});
   return TRUE;
}

sub find_user {
   my ($self, $args) = @_;

   my $rs      = $self->schema->resultset($self->result_class);
   my $method  = $self->find_user_method;
   my $options = $args->{options} // {};

   $options->{prefetch} = 'role' unless exists $options->{prefetch};

   return $rs->$method($args->{username}, $options);
}

sub to_session {
   my ($self, $args) = @_;

   my $session = $args->{session};

   return unless $session && blessed $session;

   $session->realm($self->realm) if $session->can('realm');

   my $user = $args->{user} or return;

   $self->update_session($session, $user->profile_value);

   $session->address($args->{address})
      if $session->can('address') && $args->{address};

   $session->email($user->email)     if $session->can('email');
   $session->id($user->id)           if $session->can('id');
   $session->role($user->role->name) if $session->can('role');
   $session->username($user->name)   if $session->can('username');

   return;
}

use namespace::autoclean;

1;
