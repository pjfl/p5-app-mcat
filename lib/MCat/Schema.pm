package MCat::Schema;

use strictures;
use parent 'DBIx::Class::Schema';

use MCat; our $VERSION = MCat->schema_version;
use MCat::Config; # Set exception class
use Scalar::Util qw( weaken );

my $class = __PACKAGE__;

$class->load_namespaces;
$class->load_components('Schema::Versioned');

=pod

=encoding utf-8

=head1 Name

MCat::Schema - Schema base class

=head1 Synopsis

   use 'MCat::Schema';

=head1 Description

Schema base class

=head1 Configuration and Environment

Defines no attributes

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item C<config>

=cut

my $config;

sub config {
   my ($self, $value) = @_;

   $config = $value if defined $value;

   $self->upgrade_directory($config->sqldir->as_string)
      if $self->can('upgrade_directory');

   return $config;
}

sub jobdaemon {
   my ($self, $value) = @_;

   if (defined $value) {
      weaken $value; $self->{_jobdaemon} = $value;
   }

   return $self->{_jobdaemon};
}

=item C<create_ddl_dir>

=cut

sub create_ddl_dir {
   my ($self, @args) = @_;

   local $SIG{__WARN__} = sub {
      my $error = shift;
      warn "${error}\n"
         unless $error =~ m{ Overwriting \s existing \s DDL \s file }mx;
      return 1;
   };

   return $self->SUPER::create_ddl_dir(@args);
}

=item C<deploy>

=cut

sub deploy {
   my ($self, $sqltargs, $dir) = @_;

   $self->throw_exception("Can't deploy without storage") unless $self->storage;

   eval {
      $self->storage->_get_dbh->do('DROP TABLE dbix_class_schema_versions');
   };

   $self->storage->deploy($self, undef, $sqltargs, $dir);
   return;
}

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<DBIx::Class::Schema>

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
