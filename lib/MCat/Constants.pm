package MCat::Constants;

use strictures;
use parent 'Exporter::Tiny';

use MCat::Exception;
use Class::Usul::Cmd::Constants       qw( );
use Data::Validation::Constants       qw( );
use HTML::StateTable::Constants       qw( );
use HTML::Forms::Constants            qw( );
use Web::ComposableRequest::Constants qw( );

my $exception_class = 'MCat::Exception';

Class::Usul::Cmd::Constants->Exception_Class($exception_class);
Data::Validation::Constants->Exception_Class($exception_class);
HTML::StateTable::Constants->Exception_Class($exception_class);
HTML::Forms::Constants->Exception_Class($exception_class);
Web::ComposableRequest::Constants->Exception_Class($exception_class);

our @EXPORT = qw( BUG_STATE_ENUM SQL_FALSE SQL_NOW SQL_TRUE );

=pod

=encoding utf-8

=head1 Name

MCat::Constants - Defines constants used in the application

=head1 Synopsis

   use MCat::Constants qw( SQL_NOW );

=head1 Description

Defines constants used in the application

=head1 Configuration and Environment

Defines no attributes

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item import

=cut

sub import {
   my $class       = shift;
   my $global_opts = { $_[0] && ref $_[0] eq 'HASH' ? %{+ shift } : () };
   my @wanted      = @_;
   my $usul_const  = {}; $usul_const->{$_} = 1 for (@wanted);
   my @self        = ();

   for (@EXPORT) { push @self, $_ if delete $usul_const->{$_} }

   $global_opts->{into} ||= caller;
   Class::Usul::Cmd::Constants->import($global_opts, keys %{$usul_const});
   $class->SUPER::import($global_opts, @self);
   return;
}

=item BUG_STATE_ENUM

=cut

sub BUG_STATE_ENUM () { [ qw( assigned fixed open wontfix ) ] }

=item SQL_FALSE

=cut

sub SQL_FALSE () { \q{false} }

=item SQL_NOW

=cut

sub SQL_NOW () { \q{NOW()} }

=item SQL_TRUE

=cut

sub SQL_TRUE () { \q{true} }

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Exporter::Tiny>

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
