package MCat;

use 5.010001;
use version; our $VERSION = qv( sprintf '0.2.%d', q$Rev: 37 $ =~ /\d+/gmx );

sub schema_version {
   return qv( '0.2.33' );
}

use namespace::autoclean;

1;

__END__

=pod

=encoding utf-8

=head1 Name

MCat - Music Catalog

=head1 Synopsis

   use MCat;

=head1 Description

A demo web application for L<Web::Components>, L<HTML::Forms>, and
L<HTML::StateTable>

=head1 Configuration and Environment

Defines no attributes

=head1 Subroutines/Methods

None

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo>

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

Peter Flanigan, C<< <lazarus@roxsoft.co.uk> >>

=head1 License and Copyright

Copyright (c) 2023 Peter Flanigan. All rights reserved

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
