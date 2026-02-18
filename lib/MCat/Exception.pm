package MCat::Exception;

use HTTP::Status          qw( HTTP_BAD_REQUEST HTTP_NOT_FOUND
                              HTTP_UNAUTHORIZED );
use Unexpected::Types     qw( Int Object Str );
use Type::Utils           qw( class_type );
use Unexpected::Functions qw( has_exception );
use DateTime;
use DateTime::Format::Strptime;
use MCat;
use Moo;

extends 'Class::Usul::Cmd::Exception',
   'HTML::Forms::Exception',
   'HTML::StateTable::Exception';

has 'clean_leader' =>
   is      => 'lazy',
   isa     => Str,
   default => sub {
      my $self   = shift;
      my $leader = $self->leader;

      $leader =~ s{ : [ ]* \z }{}mx;

      return $leader;
   };

has 'created' =>
   is      => 'ro',
   isa     => class_type('DateTime'),
   default => sub {
      my $dt  = DateTime->now(locale => 'en_GB', time_zone => 'UTC');
      my $fmt = DateTime::Format::Strptime->new(pattern => '%F %R');

      $dt->set_formatter($fmt);

      return $dt;
   };

has 'rv' => is => 'ro', isa => Int, default => 1;

has 'version' => is => 'ro', isa => Object, default => sub { $MCat::VERSION };

my $class = __PACKAGE__;

has '+class' => default => $class;

has_exception $class;

has_exception 'Authentication' => parents => [$class];

has_exception 'AccountInactive' => parents => ['Authentication'],
   error   => 'User [_1] account inactive';

has_exception 'AuthenticationRequired' => parents => ['Authentication'],
   error   => 'Resource [_1] authentication required';

has_exception 'IncorrectAuthCode' => parents => ['Authentication'],
   error   => 'User [_1] authentication failed';

has_exception 'IncorrectPassword' => parents => ['Authentication'],
   error   => 'User [_1] authentication failed';

has_exception 'InvalidIPAddress' => parents => ['Authentication'],
   error   => 'User [_1] invalid IP address';

has_exception 'PasswordDisabled' => parents => ['Authentication'],
   error   => 'User [_1] password disabled';

has_exception 'PasswordExpired' => parents => ['Authentication'],
   error   => 'User [_1] password expired';

has_exception 'APIMethodFailed', parents => [$class],
   error   => 'API class [_1] method [_2] call failed: [_3]',
   rv      => HTTP_BAD_REQUEST;

has_exception 'NoMethod' => parents => [$class],
   error   => 'Class [_1] has no method [_2]', rv => HTTP_NOT_FOUND;

has_exception 'PageNotFound' => parents => [$class],
   error   => 'Page [_1] not found', rv => HTTP_NOT_FOUND;

has_exception 'RedirectToLocation' => parents => [$class],
   error   => 'Redirecting to [_2]';

has_exception 'UnauthorisedAPICall' => parents => [$class],
   error   => 'Class [_1] method [_2] unauthorised call attempt',
   rv      => HTTP_UNAUTHORIZED;

has_exception 'UnknownAPIClass' => parents => [$class],
   error   => 'API class [_1] not found - [_2]', rv => HTTP_NOT_FOUND;

has_exception 'UnknownAPIMethod' => parents => [$class],
   error   => 'Class [_1] has no [_2] method', rv => HTTP_NOT_FOUND;

has_exception 'UnknownAttachment' => parents => [$class],
   error   => 'Attachment [_1] not found', rv => HTTP_NOT_FOUND;

has_exception 'UnknownBug' => parents => [$class],
   error   => 'Bug [_1] not found', rv => HTTP_NOT_FOUND;

has_exception 'UnknownArtist' => parents => [$class],
   error   => 'Artist [_1] not found', rv => HTTP_NOT_FOUND;

has_exception 'UnknownCd' => parents => [$class],
   error   => 'CD [_1] not found', rv => HTTP_NOT_FOUND;

has_exception 'UnknownModel' => parents => [$class],
   error   => 'Model [_1] (moniker) not found', rv => HTTP_NOT_FOUND;

has_exception 'UnknownTag' => parents => [$class],
   error   => 'Tag [_1] not found', rv => HTTP_NOT_FOUND;

has_exception 'UnknownTrack' => parents => [$class],
   error   => 'Track [_1] not found', rv => HTTP_NOT_FOUND;

has_exception 'UnknownUser' => parents => [$class],
   error   => 'User [_1] not found', rv => HTTP_NOT_FOUND;

has_exception 'NoUserRole' => parents => [$class],
   error   => 'User [_1] no role found on session', rv => HTTP_NOT_FOUND;

has_exception 'UnauthorisedAccess' => parents => [$class],
   error   => 'Access to resource denied', rv => HTTP_UNAUTHORIZED;

has_exception 'UnknownToken' => parents => [$class],
   error   => 'Token [_1] not found', rv => HTTP_NOT_FOUND;

has_exception 'UnknownTable' => parents => [$class],
   error   => 'Table [_1] not found', rv => HTTP_NOT_FOUND;

has_exception 'UnknownList' => parents => [$class],
   error   => 'List [_1] not found', rv => HTTP_NOT_FOUND;

has_exception 'UnknownFilter' => parents => [$class],
   error   => 'Filter [_1] not found', rv => HTTP_NOT_FOUND;

has_exception 'UnknownSelector' => parents => [$class],
   error   => 'Selector [_1] not found', rv => HTTP_NOT_FOUND;

has_exception 'UnknownImport' => parents => [$class],
   error   => 'Import [_1] not found', rv => HTTP_NOT_FOUND;

has_exception 'UnknownImportLog' => parents => [$class],
   error   => 'Import log [_1] not found', rv => HTTP_NOT_FOUND;

use namespace::autoclean;

1;
