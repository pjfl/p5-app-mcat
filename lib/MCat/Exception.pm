package MCat::Exception;

use DateTime;
use HTML::Forms::Types    qw( Object );
use HTTP::Status          qw( HTTP_NOT_FOUND );
use Type::Utils           qw( class_type );
use Unexpected::Functions qw( has_exception );
use MCat;
use Moo;

extends 'HTML::Forms::Exception';

has 'created' => is => 'ro', isa => class_type('DateTime'), default => sub {
   return DateTime->now( locale => 'en_GB', time_zone => 'UTC' );
};

has 'version' => is => 'ro', isa => Object, default => sub { $MCat::VERSION };

my $class = __PACKAGE__;

has '+class' => default => $class;

has_exception $class;

has_exception 'APIMethodFailed', parent => [$class],
   error => 'API class [_1] method [_2] call failed: [_3]';

has_exception 'NoMethod' => parent => [$class],
   error => 'Class [_1] has no method [_2]';

has_exception 'PageNotFound' => parent => [$class],
   error => 'Page [_1] not found', rv => HTTP_NOT_FOUND;

has_exception 'UnknownAPIClass' => parent => [$class],
   error => 'API class [_1] not found', rv => HTTP_NOT_FOUND;

has_exception 'UnknownAPIMethod' => parent => [$class],
   error => 'Class [_1] has no [_2] method', rv => HTTP_NOT_FOUND;

has_exception 'UnknownArtist' => parent => [$class],
   error => 'Artist [_1] not found', rv => HTTP_NOT_FOUND;

has_exception 'UnknownCd' => parent => [$class],
   error => 'CD [_1] not found', rv => HTTP_NOT_FOUND;

has_exception 'UnknownModel' => parent => [$class],
   error => 'Model [_1] (moniker) unknown', rv => HTTP_NOT_FOUND;

has_exception 'UnknownTag' => parent => [$class],
   error => 'Tag [_1] not found', rv => HTTP_NOT_FOUND;

has_exception 'UnknownTrack' => parent => [$class],
   error => 'Track [_1] not found', rv => HTTP_NOT_FOUND;

use namespace::autoclean;

1;
