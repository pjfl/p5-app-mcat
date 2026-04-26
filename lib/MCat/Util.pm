package MCat::Util;

use utf8; # -*- coding: utf-8; -*-
use strictures;
use parent 'Exporter::Tiny';

use Digest                qw( );
use English               qw( -no_match_vars );
use File::DataClass::IO   qw( io );
use HTML::Entities        qw( encode_entities );
use JSON::MaybeXS         qw( encode_json );
use Ref::Util             qw( is_hashref );
use Unexpected::Functions qw( throw );
use URI::Escape           qw( );
use URI::http;
use URI::https;
use DateTime;
use DateTime::Format::Human;

our @EXPORT = qw( base64_decode base64_encode create_token create_totp_token
                  digest dt_from_epoch dt_human encode_for_html formpost
                  new_uri redirect redirect2referer truncate urandom
                  uri_escape );

my $digest_cache;
my $reserved   = q(;/?:@&=+$,[]);
my $mark       = q(-_.!~*'());                                   #'; emacs
my $unreserved = "A-Za-z0-9\Q${mark}\E%\#";
my $uric       = quotemeta($reserved) . '\p{isAlpha}' . $unreserved;

my $base64_char_set = sub { [ 0 .. 9, 'A' .. 'Z', '_', 'a' .. 'z', '~', '+' ] };
my $index64 = sub { [
   qw(XX XX XX XX  XX XX XX XX  XX XX XX XX  XX XX XX XX
      XX XX XX XX  XX XX XX XX  XX XX XX XX  XX XX XX XX
      XX XX XX XX  XX XX XX XX  XX XX XX 64  XX XX XX XX
       0  1  2  3   4  5  6  7   8  9 XX XX  XX XX XX XX
      XX 10 11 12  13 14 15 16  17 18 19 20  21 22 23 24
      25 26 27 28  29 30 31 32  33 34 35 XX  XX XX XX 36
      XX 37 38 39  40 41 42 43  44 45 46 47  48 49 50 51
      52 53 54 55  56 57 58 59  60 61 62 XX  XX XX 63 XX

      XX XX XX XX  XX XX XX XX  XX XX XX XX  XX XX XX XX
      XX XX XX XX  XX XX XX XX  XX XX XX XX  XX XX XX XX
      XX XX XX XX  XX XX XX XX  XX XX XX XX  XX XX XX XX
      XX XX XX XX  XX XX XX XX  XX XX XX XX  XX XX XX XX
      XX XX XX XX  XX XX XX XX  XX XX XX XX  XX XX XX XX
      XX XX XX XX  XX XX XX XX  XX XX XX XX  XX XX XX XX
      XX XX XX XX  XX XX XX XX  XX XX XX XX  XX XX XX XX
      XX XX XX XX  XX XX XX XX  XX XX XX XX  XX XX XX XX)
]};

=pod

=encoding utf-8

=head1 Name

MCat::Util - Utility functions

=head1 Synopsis

   use MCat::Log;

=head1 Description

Utility functions

=head1 Configuration and Environment

Defines no attributes

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item C<base64_decode>

   $decoded = base64_decode $encoded;

=cut

sub base64_decode ($) {
   my $x = shift;

   return unless defined $x;

   my @x = split q(), $x;
   my $index = $index64->();
   my $j = 0;
   my $k = 0;
   my $len = length $x;
   my $pad = 64;
   my @y = ();

 ROUND: {
    while ($j < $len) {
       my @c = ();
       my $i = 0;

       while ($i < 4) {
          my $uc = $index->[ord $x[$j++]];

          $c[$i++] = 0 + $uc if $uc ne 'XX';
          next unless $j == $len;

          if ($i < 4) {
             last ROUND if $i < 2;
             $c[2] = $pad if $i == 2;
             $c[3] = $pad;
          }

          last;
       }

       last if $c[0] == $pad or $c[1] == $pad;
       $y[$k++] = ( $c[0] << 2) | (($c[1] & 0x30) >> 4);
       last if $c[2] == $pad;
       $y[$k++] = (($c[1] & 0x0F) << 4) | (($c[2] & 0x3C) >> 2);
       last if $c[3] == $pad;
       $y[$k++] = (($c[2] & 0x03) << 6) | $c[3];
    }
 }

   return join q(), map { chr $_ } @y;
}

=item C<base64_encode>

   $encoded = base64_encode $decoded;

=cut

sub base64_encode (;$) {
   my $x = shift;

   return unless defined $x;

   my @x = split q(), $x;
   my $basis = $base64_char_set->();
   my $len = length $x;
   my @y = ();

   for (my $i = 0, my $j = 0; $len > 0; $len -= 3, $i += 3) {
      my $c1 = ord $x[$i];
      my $c2 = $len > 1 ? ord $x[$i + 1] : 0;

      $y[$j++] = $basis->[$c1 >> 2];
      $y[$j++] = $basis->[(($c1 & 0x3) << 4) | (($c2 & 0xF0) >> 4)];

      if ($len > 2) {
         my $c3 = ord $x[$i + 2];

         $y[$j++] = $basis->[(($c2 & 0xF) << 2) | (($c3 & 0xC0) >> 6)];
         $y[$j++] = $basis->[$c3 & 0x3F];
      }
      elsif ($len == 2) {
         $y[$j++] = $basis->[($c2 & 0xF) << 2];
         $y[$j++] = $basis->[64];
      }
      else { # len == 1
         $y[$j++] = $basis->[64];
         $y[$j++] = $basis->[64];
      }
   }

   return join q(), @y;
}

=item C<create_token>

   $token = create_token;

=cut

sub create_token () {
   return substr digest(urandom())->hexdigest, 0, 32;
}

=item C<create_totp_token>

   $token = create_totp_token;

=cut

sub create_totp_token () {
   return substr digest(urandom())->b64digest, 0, 16;
}

=item C<digest>

   $digest = digest $seed;

=cut

sub digest ($) {
   my $seed = shift;

   my ($candidate, $digest);

   if ($digest_cache) { $digest = Digest->new($digest_cache) }
   else {
      for (qw( SHA-512 SHA-256 SHA-1 MD5 )) {
         $candidate = $_;
         last if $digest = eval { Digest->new($candidate) };
      }

      throw 'Digest algorithm not found' unless $digest;
      $digest_cache = $candidate;
   }

   $digest->add($seed);

   return $digest;
}

=item C<dt_from_epoch>

   $datetime = dt_from_epoch $epoch, $timezone?;

=cut

sub dt_from_epoch ($;$) {
   my ($epoch, $tz) = @_;

   return DateTime->from_epoch(
      epoch => $epoch, locale => 'en_GB', time_zone => $tz // 'UTC'
   );
}

=item C<dt_human>

   $datetime = dt_human $datetime;

=cut

sub dt_human ($) {
   my $dt  = shift;
   my $fmt = DateTime::Format::Human->new(evening => 19, night => 23);

   $dt->set_formatter($fmt);
   return $dt;
}

=item C<encode_for_html>

   $encoded = encode_entities $payload;

=cut

sub encode_for_html ($) {
   return encode_entities(encode_json(shift));
}

=item C<formpost>

   $hash_ref = formpost;

=cut

sub formpost () {
   return { 'method' => 'post' };
}

=item C<new_uri>

   $uri = new_uri $schema, $uri_path;

=cut

sub new_uri ($$) {
   my $v = uri_escape($_[1]); return bless \$v, 'URI::'.$_[0];
}

=item C<redirect>

   $stash_attr = redirect $location, $message, $options?;

=cut

sub redirect ($$;$) {
   return redirect => {%{$_[2] // {}}, 'location' => $_[0], 'message' => $_[1]};
}

=item C<redirect2referer>

   $stash_attr = redirect2referer $context, $message;

=cut

sub redirect2referer ($;$) {
   my ($context, $message) = @_;

   my $referer = new_uri 'http', $context->request->referer;

   return redirect $referer, $message;
}

=item C<truncate>

   $truncated = truncate $string, $length?;

Truncates the given C<string> to the specifed C<length>. Length defaults to
eighty characters

=cut

sub truncate ($;$) {
   my ($string, $length) = @_;

   $length //= 80;
   return substr($string, 0, $length - 1) . '…';
}

=item C<urandom>

   $random = urandom $wanted?, $options?;

Reads random bytes from OS device file. The number of bytes C<wanted> defaults
to sixty four

The C<options> hash reference keys are;

=over 3

=item C<source>

Specify the path to the device file. Should default correctly for Linux
and BSD

=back

=cut

sub urandom (;$$) {
   my ($wanted, $opts) = @_;

   $wanted //= 64; $opts //= {};

   my $default = [q(), 'dev', $OSNAME eq 'freebsd' ? 'random' : 'urandom'];
   my $io      = io($opts->{source} // $default)->block_size($wanted);

   if ($io->exists and $io->is_readable and my $red = $io->read) {
      return ${ $io->buffer } if $red == $wanted;
   }

   my $res = q();

   while (length $res < $wanted) { $res .= _pseudo_random() }

   return substr $res, 0, $wanted;
}

=item C<uri_escape>

   $escaped = uri_escape $string, $pattern?;

=cut

sub uri_escape ($;$) {
   my ($v, $pattern) = @_; $pattern //= $uric;

   $v =~ s{([^$pattern])}{ URI::Escape::uri_escape_utf8($1) }ego;
   utf8::downgrade( $v );
   return $v;
}

sub _pseudo_random {
   return join q(), time, rand 10_000, $PID, {};
}

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<DateTime>

=item L<DateTime::Format::Human>

=item L<Digest>

=item L<File::DataClass::IO>

=item L<HTML::Entities>

=item L<JSON::MaybeXS>

=item L<URI>

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
