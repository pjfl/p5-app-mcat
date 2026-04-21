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

=pod

=encoding utf-8

=head1 Name

MCat::Exception - Application level exceptions

=head1 Synopsis

   use MCat::Exception;

=head1 Description

Application level exceptions

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<clean_leader>



=cut

has 'clean_leader' =>
   is      => 'lazy',
   isa     => Str,
   default => sub {
      my $self   = shift;
      my $leader = $self->leader;

      $leader =~ s{ : [ ]* \z }{}mx;

      return $leader;
   };

=item C<created>

=cut

has 'created' =>
   is      => 'ro',
   isa     => class_type('DateTime'),
   default => sub {
      my $dt  = DateTime->now(locale => 'en_GB', time_zone => 'UTC');
      my $fmt = DateTime::Format::Strptime->new(pattern => '%F %R');

      $dt->set_formatter($fmt);

      return $dt;
   };

=item C<rv>

=cut

has 'rv' => is => 'ro', isa => Int, default => 1;

=item C<version>

=cut

has 'version' => is => 'ro', isa => Object, default => sub { $MCat::VERSION };

my $class = __PACKAGE__;

has '+class' => default => $class;

=back

=head1 Exceptions

Defines the following exceptions;

=over 3

=cut

has_exception $class;

=item C<APIMethodFailed>

=cut

has_exception 'APIMethodFailed', parents => [$class],
   error   => 'API class [_1] method [_2] call failed: [_3]',
   rv      => HTTP_BAD_REQUEST;

=item C<Authentication>

=cut

has_exception 'Authentication' => parents => [$class];

=item C<AccountInactive>

=cut

has_exception 'AccountInactive' => parents => ['Authentication'],
   error   => 'User [_1] account inactive';

=item C<AuthenticationRequired>

=cut

has_exception 'AuthenticationRequired' => parents => ['Authentication'],
   error   => 'Resource [_1] authentication required';

=item C<IncorrectAuthCode>

=cut

has_exception 'IncorrectAuthCode' => parents => ['Authentication'],
   error   => 'User [_1] authentication failed';

=item C<IncorrectPassword>

=cut

has_exception 'IncorrectPassword' => parents => ['Authentication'],
   error   => 'User [_1] authentication failed';

=item C<InvalidIPAddress>

=cut

has_exception 'InvalidIPAddress' => parents => ['Authentication'],
   error   => 'User [_1] invalid IP address';

=item C<PasswordDisabled>

=cut

has_exception 'PasswordDisabled' => parents => ['Authentication'],
   error   => 'User [_1] password disabled';

=item C<PasswordExpired>

=cut

has_exception 'PasswordExpired' => parents => ['Authentication'],
   error   => 'User [_1] password expired';

=item C<NoMethod>

=cut

has_exception 'NoMethod' => parents => [$class],
   error   => 'Class [_1] has no method [_2]', rv => HTTP_NOT_FOUND;

=item C<NoUserRole>

=cut

has_exception 'NoUserRole' => parents => [$class],
   error   => 'User [_1] no role found on session', rv => HTTP_NOT_FOUND;

=item C<PageNotFound>

=cut

has_exception 'PageNotFound' => parents => [$class],
   error   => 'Page [_1] not found', rv => HTTP_NOT_FOUND;

=item C<RedirectToLocation>

=cut

has_exception 'RedirectToLocation' => parents => [$class],
   error   => 'Redirecting to [_2]';

=item C<UnauthorisedAPICall>

=cut

has_exception 'UnauthorisedAPICall' => parents => [$class],
   error   => 'Class [_1] method [_2] unauthorised call attempt',
   rv      => HTTP_UNAUTHORIZED;

=item C<UnauthorisedAccess>

=cut

has_exception 'UnauthorisedAccess' => parents => [$class],
   error   => 'Access to resource denied', rv => HTTP_UNAUTHORIZED;

=item C<UnknownAPIClass>

=cut

has_exception 'UnknownAPIClass' => parents => [$class],
   error   => 'API class [_1] not found - [_2]', rv => HTTP_NOT_FOUND;

=item C<UnknownAPIMethod>

=cut

has_exception 'UnknownAPIMethod' => parents => [$class],
   error   => 'Class [_1] has no [_2] method', rv => HTTP_NOT_FOUND;

=item C<UnknownAttachment>

=cut

has_exception 'UnknownAttachment' => parents => [$class],
   error   => 'Attachment [_1] not found', rv => HTTP_NOT_FOUND;

=item C<UnknownBug>

=cut

has_exception 'UnknownBug' => parents => [$class],
   error   => 'Bug [_1] not found', rv => HTTP_NOT_FOUND;

=item C<UnknownArtist>

=cut

has_exception 'UnknownArtist' => parents => [$class],
   error   => 'Artist [_1] not found', rv => HTTP_NOT_FOUND;

=item C<UnknownCd>

=cut

has_exception 'UnknownCd' => parents => [$class],
   error   => 'CD [_1] not found', rv => HTTP_NOT_FOUND;

=item C<UnknownModel>

=cut

has_exception 'UnknownModel' => parents => [$class],
   error   => 'Model [_1] (moniker) not found', rv => HTTP_NOT_FOUND;

=item C<UnknownTag>

=cut

has_exception 'UnknownTag' => parents => [$class],
   error   => 'Tag [_1] not found', rv => HTTP_NOT_FOUND;

=item C<UnknownTrack>

=cut

has_exception 'UnknownTrack' => parents => [$class],
   error   => 'Track [_1] not found', rv => HTTP_NOT_FOUND;

=item C<UnknownUser>

=cut

has_exception 'UnknownUser' => parents => [$class],
   error   => 'User [_1] not found', rv => HTTP_NOT_FOUND;

=item C<UnknownRealm>

=cut

has_exception 'UnknownRealm' => parents => [$class],
   error   => 'Realm [_1] not found', rv => HTTP_NOT_FOUND;

=item C<UnknownToken>

=cut

has_exception 'UnknownToken' => parents => [$class],
   error   => 'Token [_1] not found', rv => HTTP_NOT_FOUND;

=item C<UnknownTable>

=cut

has_exception 'UnknownTable' => parents => [$class],
   error   => 'Table [_1] not found', rv => HTTP_NOT_FOUND;

=item C<UnknownList>

=cut

has_exception 'UnknownList' => parents => [$class],
   error   => 'List [_1] not found', rv => HTTP_NOT_FOUND;

=item C<UnknownFilter>

=cut

has_exception 'UnknownFilter' => parents => [$class],
   error   => 'Filter [_1] not found', rv => HTTP_NOT_FOUND;

=item C<UnknownSelector>

=cut

has_exception 'UnknownSelector' => parents => [$class],
   error   => 'Selector [_1] not found', rv => HTTP_NOT_FOUND;

=item C<UnknownImport>

=cut

has_exception 'UnknownImport' => parents => [$class],
   error   => 'Import [_1] not found', rv => HTTP_NOT_FOUND;

=item C<UnknownImportLog>

=cut

has_exception 'UnknownImportLog' => parents => [$class],
   error   => 'Import log [_1] not found', rv => HTTP_NOT_FOUND;

use namespace::autoclean;

1;

__END__

=back

=head1 Subroutines/Methods

Defines no methods

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Class::Usul::Cmd::Exception>

=item L<HTML::Forms::Exception>

=item L<HTML::StateTable::Exception>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=MCat.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2025 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
