package MCat::Redis;

use HTML::StateTable::Constants qw( EXCEPTION_CLASS FALSE TRUE );
use HTML::StateTable::Types     qw( HashRef Int Str );
use List::Util                  qw( shuffle );
use Type::Utils                 qw( class_type );
use Unexpected::Functions       qw( throw );
use Redis;
use Moo;

our $AUTOLOAD;

has 'client_name' => is => 'ro', isa => Str, required => TRUE;

has 'config' => is => 'ro', isa => HashRef, default => sub { {} };

has 'redis' =>
    is      => 'lazy',
    isa     => class_type('Redis'),
    default => sub {
      my $self   = shift;
      my $params = { %{$self->config} };

      throw 'No Redis config' unless scalar keys %{$params};

      throw 'No recognisable Redis config' unless exists $params->{sentinel}
         || exists $params->{server} || exists $params->{socket};

      if (exists $params->{sentinel}) {
         my @sentinels = split m{ , \s* }mx, delete $params->{sentinel};

         @sentinels = shuffle @sentinels if $params->{ordering} eq 'random';

         $params->{sentinels} = \@sentinels;
         delete $params->{ordering};
      }

      $params->{on_connect} = sub {
         my $redis      = shift;
         my $start_time = time;

         while (!$redis->ping) {
            sleep 1;
            return FALSE if time - $start_time > 3600;
         }

         return TRUE;
      };

      my $r = Redis->new(%{$params});

      $r->client_setname($self->client_name);
      return $r;
   };

sub DEMOLISH {
    my $self = shift;

    $self->redis->quit if ${^GLOBAL_PHASE} ne 'DESTRUCT';
}

sub AUTOLOAD {
    my ($self, @args) = @_;

    throw "${self} is not an object" unless ref $self;

    my $name = $AUTOLOAD; $name =~ s{ \A .* :: }{}mx;

    return $self->redis->$name(@args);
}

sub set_preserve_ttl {
   my ($self, $key, $value) = @_;

   my $redis = $self->redis;
   my $expiry_time_ms = $redis->pttl($key) // return;

   $redis->set($key, $value) or return;
   $redis->pexpire($key, $expiry_time_ms);
   return;
}

use namespace::autoclean;

1;

__END__

=pod

=encoding utf-8

=head1 Name

MCat::Redis - Music Catalog

=head1 Synopsis

   use MCat::Redis;
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
