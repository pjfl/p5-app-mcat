package MCat::Exception;

use DateTime;
use HTML::Forms::Types    qw( Int Object );
use HTTP::Status          qw( HTTP_NOT_FOUND );
use Type::Utils           qw( class_type );
use Unexpected::Functions qw( has_exception );
use MCat;
use Moo;

extends 'HTML::Forms::Exception', 'HTML::StateTable::Exception';

has 'created' => is => 'ro', isa => class_type('DateTime'), default => sub {
   return DateTime->now( locale => 'en_GB', time_zone => 'UTC' );
};

has 'rv' => is => 'ro', isa => Int, default => 1;

has 'version' => is => 'ro', isa => Object, default => sub { $MCat::VERSION };

my $class = __PACKAGE__;

has '+class' => default => $class;

has_exception $class;

has_exception 'Authentication' => parents => [$class];

has_exception 'AccountInactive' => parents => ['Authentication'],
   error   => 'User [_1] authentication failed';

has_exception 'AuthenticationRequired' => parents => ['Authentication'],
   error   => 'Resource [_1] authentication required';

has_exception 'FailedSecurityCheck' => parents => ['Authentication'],
   error   => 'User [_1] authentication failed';

has_exception 'IncorrectAuthCode' => parents => ['Authentication'],
   error   => 'User [_1] authentication failed';

has_exception 'IncorrectPassword' => parents => ['Authentication'],
   error   => 'User [_1] authentication failed';

has_exception 'PasswordDisabled' => parents => ['Authentication'],
   error   => 'User [_1] password disabled';

has_exception 'PasswordExpired' => parents => ['Authentication'],
   error   => 'User [_1] password expired';

has_exception 'APIMethodFailed', parent => [$class],
   error   => 'API class [_1] method [_2] call failed: [_3]';

has_exception 'NoMethod' => parent => [$class],
   error   => 'Class [_1] has no method [_2]';

has_exception 'PageNotFound' => parent => [$class],
   error   => 'Page [_1] not found', rv => HTTP_NOT_FOUND;

has_exception 'UnauthorisedAPICall' => parent => [$class],
   error   => 'Class [_1] method [_2] unauthorised call attempt';

has_exception 'UnknownAPIClass' => parent => [$class],
   error   => 'API class [_1] not found', rv => HTTP_NOT_FOUND;

has_exception 'UnknownAPIMethod' => parent => [$class],
   error   => 'Class [_1] has no [_2] method', rv => HTTP_NOT_FOUND;

has_exception 'UnknownArtist' => parent => [$class],
   error   => 'Artist [_1] not found', rv => HTTP_NOT_FOUND;

has_exception 'UnknownCd' => parent => [$class],
   error   => 'CD [_1] not found', rv => HTTP_NOT_FOUND;

has_exception 'UnknownModel' => parent => [$class],
   error   => 'Model [_1] (moniker) not found', rv => HTTP_NOT_FOUND;

has_exception 'UnknownTag' => parent => [$class],
   error   => 'Tag [_1] not found', rv => HTTP_NOT_FOUND;

has_exception 'UnknownTrack' => parent => [$class],
   error   => 'Track [_1] not found', rv => HTTP_NOT_FOUND;

has_exception 'UnknownUser' => parent => [$class],
   error   => 'User [_1] not found', rv => HTTP_NOT_FOUND;

has_exception 'NoUserRole' => parent => [$class],
   error   => 'User [_1] no role found on session', rv => HTTP_NOT_FOUND;

has_exception 'UnauthorisedDataAccess' => parent => [$class],
   error   => 'Access to resource denied';

has_exception 'UnknownToken' => parent => [$class],
   error   => 'Token [_1] not found', rv => HTTP_NOT_FOUND;

use namespace::autoclean;

1;
