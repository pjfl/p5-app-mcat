package MCat::JobServer;

use App::Job::Daemon; our $VERSION = App::Job::Daemon->VERSION;

use Class::Usul::Cmd::Constants qw( TRUE );
use Class::Usul::Cmd::Types     qw( LoadableClass );
use Type::Utils                 qw( class_type );
use Moo;

extends 'App::Job::Daemon';

with 'MCat::Role::Config';
with 'MCat::Role::Log';

=pod

=encoding utf-8

=head1 Name

MCat::JobServer - Interface job system

=head1 Synopsis

   use MCat::JobServer;

=head1 Description

Interface to L<App::Job::Daemon>

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<lock>

An instance of L<IPC::SRLock>

=cut

has 'lock' =>
   is      => 'lazy',
   isa     => class_type('IPC::SRLock'),
   default => sub { $_[0]->_lock_class->new($_[0]->config->lock_attributes) };

has '_lock_class' =>
   is      => 'lazy',
   isa     => LoadableClass,
   coerce  => TRUE,
   default => 'IPC::SRLock';

=back

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

=item L<App::Job::Daemon>

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

Copyright (c) 2026 Peter Flanigan. All rights reserved

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
