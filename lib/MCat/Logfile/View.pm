package MCat::Logfile::View;

use File::DataClass::Types      qw( File );
use HTML::StateTable::Constants qw( DOT FALSE TRUE );
use HTML::StateTable::Types     qw( HashRef Str );
use Type::Utils                 qw( class_type );
use MCat::Logfile::Cache;
use Moo;

extends 'MCat::Logfile';

has 'cache' =>
   is      => 'lazy',
   isa     => class_type('MCat::Logfile::Cache'),
   default => sub {
      my $self = shift;

      return MCat::Logfile::Cache->new(
         config => $self->cache_config, resultset => $self
      );
   };

has 'cache_config' => is => 'ro', isa => HashRef, default => sub { {} };

has 'logfile' => is => 'ro', isa => Str, required => TRUE;

has 'path' =>
   is      => 'lazy',
   isa     => File,
   default => sub {
      my $self = shift;
      my $path = $self->logfile;

      $path .= DOT . $self->extension if $self->extension;

      return $self->base->catfile($path);
   };

has '+result_class' => default => 'MCat::Logfile::View::Result';

has '+total_results' => default => sub { shift->cache->count };

sub build_results {
   my $self = shift;

   return $self->process($self->cache->read);
}

sub has_column_filter {
   my $self = shift;

   return FALSE unless $self->has_distinct_column;

   my $method = $self->distinct_column->[0] . '_filter';

   return $self->result_class->can($method) ? TRUE : FALSE;
}

around '_sort_results' => sub {
   my ($orig, $self, $results) = @_;

   if ($self->_sort_column eq 'timestamp') {
      return $self->_sort_order eq 'asc' ? $results : [ reverse @{$results} ];
   }

   return $orig->($self, $results);
};

use namespace::autoclean;

1;

__END__

=pod

=encoding utf-8

=head1 Name

MCat::Logfile::View - Music Catalog

=head1 Synopsis

   use MCat::Logfile::View;
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

=item L<Class::Usul>

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
