package MCat::Redis;

use Class::Usul::Cmd::Constants qw( EXCEPTION_CLASS FALSE TRUE );
use Unexpected::Types           qw( HashRef Int Str );
use List::Util                  qw( shuffle );
use Scalar::Util                qw( blessed );
use Type::Utils                 qw( class_type );
use Unexpected::Functions       qw( throw );
use Redis;
use Moo;

our $AUTOLOAD;

=pod

=encoding utf-8

=head1 Name

MCat::Redis - Proxy class for the Redis client

=head1 Synopsis

   use MCat::Redis;

=head1 Description

Proxy class for the Redis client

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item client_name

An immutable required string. Used as a prefix to the key space. Each instance
of this class should use a unique value

=cut

has 'client_name' => is => 'ro', isa => Str, required => TRUE;

=item config

An immutable hash reference with an empty default. Provides the L<Redis>
client specific configuration

=cut

has 'config' => is => 'ro', isa => HashRef, default => sub { {} };

=item redis

A lazy instance of L<Redis>

=cut

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
            sleep 1; return FALSE if time - $start_time > 3600;
         }

         return TRUE;
      };

      my $r = Redis->new(%{$params});

      $r->client_setname($self->client_name);
      return $r;
   };

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item DEMOLISH

Quits the L<Redis> session when this instance goes out of scope

=cut

sub DEMOLISH {
    my ($self, $in_global_destruction) = @_;

    $self->redis->quit unless $in_global_destruction;
    return;
}

=item AUTOLOAD

Proxy all of the L<Redis> methods

=cut

sub AUTOLOAD {
    my ($self, @args) = @_;

    throw "${self} is not an object" unless blessed $self;

    my $name = $AUTOLOAD; $name =~ s{ \A .* :: }{}mx;

    return $self->redis->$name(@args);
}

=item set_preserve_ttl( key, value )

Sets the C<value> on the C<key> preserving the time to live of the original
entry

=cut

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

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Redis>

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
