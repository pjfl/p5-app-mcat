package MCat::Authentication::Realms::DBIC;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE TRUE );
use HTML::Forms::Types     qw( Str );
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

has 'to_session_method' =>
   is      => 'ro',
   isa     => Str,
   default => 'to_session';

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

   return unless $args->{user};

   my $session = $args->{session} or return;

   $session->realm($self->realm) if $session->can('realm');

   my $method = $self->to_session_method;

   return $args->{user}->$method($session);
}

use namespace::autoclean;

1;
