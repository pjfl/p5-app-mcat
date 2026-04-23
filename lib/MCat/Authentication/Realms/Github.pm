package MCat::Authentication::Realms::Github;

use Moo;

extends 'MCat::Authentication::Realms::OAuth';

=pod

=encoding utf-8

=head1 Name

MCat::Authentication::Realms::Github - Authenticate with Github

=head1 Synopsis

   use MCat::Authentication::Realms::Github;

=head1 Description

Authenticate with Github as the OAuth provider

=head1 Configuration and Environment

Defines no attributes

=head1 Subroutines/Methods

Defines no methods

=cut

use namespace::autoclean;

1;

__END__

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<MCat::Authentication::Realms::OAuth>

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
