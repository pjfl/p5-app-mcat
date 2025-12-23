package MCat::Schema::Result::ImportLog;

use Class::Usul::Cmd::Constants qw( FALSE TRUE );
use DBIx::Class::Moo::ResultClass;

my $class  = __PACKAGE__;
my $result = 'MCat::Schema::Result';

$class->load_components('InflateColumn::DateTime');
$class->table('import_log');

$class->add_columns(
   import_log_id => {
      data_type         => 'integer',
      hidden            => TRUE,
      is_auto_increment => TRUE,
      is_nullable       => FALSE,
      label             => 'Import Log ID'
   },
   guid => {
      data_type   => 'text',
      is_nullable => FALSE,
      label       => 'Unique ID',
      sort_case   => 'sensitive'
   },
   source => {
      data_type => 'text', is_nullable => FALSE, label => 'Source File'
   },
   import_id => {
      data_type   => 'integer',
      display     => 'import.core_table.name',
      is_nullable => FALSE,
      label       => 'Imported Into'
   },
   owner_user_id => {
      data_type   => 'integer',
      display     => 'owner.name',
      is_nullable => FALSE,
      label       => 'Owner'
   },
   started => {
      cell_traits => ['DateTime'],
      data_type   => 'timestamp',
      is_nullable => FALSE,
      timezone    => 'UTC'
   },
   finished => {
      cell_traits => ['DateTime'],
      data_type   => 'timestamp',
      is_nullable => TRUE,
      timezone    => 'UTC'
   },
   inserted => {
      data_type   => 'integer',
      default     => 0,
      is_nullable => TRUE
   },
   updated => {
      data_type   => 'integer',
      default     => 0,
      is_nullable => TRUE
   }
);

$class->set_primary_key('import_log_id');

$class->belongs_to('import', "${result}::Import", {
   'foreign.id' => 'self.import_id'
});

$class->belongs_to('owner', "${result}::User", {
   'foreign.id' => 'self.owner_user_id'
});

sub count {
   my $self = shift; return $self->inserted + $self->updated;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

MCat::Schema::Result::ImportLog - Music Catalog

=head1 Synopsis

   use MCat::Schema::Result::ImportLog;
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

=item L<Class::Usul::Cmd>

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
