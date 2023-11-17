package MCat::Logfile::List::Result;

use DateTime;
use File::DataClass::Types      qw( Directory File );
use HTML::StateTable::Constants qw( FALSE TRUE );
use HTML::StateTable::Types     qw( Date Int Str );
use MCat::Util                  qw( local_tz );
use Type::Utils                 qw( class_type );
use Moo;

with 'HTML::StateTable::Result::Role';

has 'base' => is => 'ro', isa => Directory, required => TRUE;

has 'extension' => is => 'ro', isa => Str, predicate => 'has_extension';

has 'modified' =>
   is      => 'lazy',
   isa     => Date,
   default => sub {
      my $self = shift;

      return DateTime->from_epoch(
         epoch => $self->path->stat->{mtime}, time_zone => local_tz
      );
   };

has 'name' =>
   is      => 'lazy',
   isa     => Str,
   default => sub {
      my $self      = shift;
      my $name      = $self->path->clone->relative($self->base);
      my $extension = $self->extension;

      $name =~ s{ \. $extension \z }{}mx if $self->has_extension;

      return $name;
   };

has 'path' => is => 'ro', isa => File, coerce => TRUE, required => TRUE;

has 'size' =>
   is      => 'lazy',
   isa     => Int,
   default => sub { shift->path->stat->{size} };

has 'uri_arg' =>
   is      => 'lazy',
   isa     => Str,
   default => sub {
      my $self = shift;

      (my $name = $self->name) =~ s{ / }{!}gmx;

      return $name;
   };

use namespace::autoclean;

1;

__END__

=pod

=encoding utf-8

=head1 Name

MCat::Logfile::List::Result - Music Catalog

=head1 Synopsis

   use MCat::Logfile::List::Result;
   # Brief but working code examples

=head1 Description

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=back

=head1 Subroutines/Methods

=head1 Diagnostics

=head1 Dependencies

=over 3

=item L<DateTime>

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
