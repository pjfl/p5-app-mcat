package MCat::Util;

use strictures;

use DateTime;
use Digest                qw( );
use English               qw( -no_match_vars );
use File::DataClass::IO   qw( io );
use Ref::Util             qw( is_hashref );
use Unexpected::Functions qw( throw );
use URI::Escape           qw( );
use URI::http;
use URI::https;

use Sub::Exporter -setup => { exports => [
   qw( clear_redirect digest formpost local_tz maybe_render_partial
       new_uri now redirect redirect2referer trim urandom uri_escape )
]};

my $digest_cache;
my $reserved   = q(;/?:@&=+$,[]);
my $mark       = q(-_.!~*'());                                   #'; emacs
my $unreserved = "A-Za-z0-9\Q${mark}\E%\#";
my $uric       = quotemeta($reserved) . '\p{isAlpha}' . $unreserved;

sub clear_redirect ($) {
   return delete shift->stash->{redirect};
}

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

sub formpost () {
   return { method => 'post' };
}

sub local_tz () {
   return 'Europe/London';
}

sub new_uri ($$) {
   my $v = uri_escape($_[1]); return bless \$v, 'URI::'.$_[0];
}

sub now (;$$) {
   my ($tz, $locale) = @_;

   my $args = { locale => 'en_GB', time_zone => 'UTC' };

   $args->{locale}    = $locale if $locale;
   $args->{time_zone} = $tz     if $tz;

   return DateTime->now(%{$args});
}

sub redirect ($$) {
   return redirect => { location => $_[0], message => $_[1] };
}

sub redirect2referer ($;$) {
   my ($context, $message) = @_;

   my $referer = new_uri 'http', $context->request->referer;

   return redirect $referer, $message;
}

=item trim( string, characters )

Trims whitespace characters from both ends of the supplied string and returns
it. The list of C<characters> to remove is optional and defaults to space and
tab. Newlines at the end of the string are also removed

=cut

sub trim (;$$) {
   my $chars = $_[1] // " \t";
   (my $value = $_[0] // q()) =~ s{ \A [$chars]+ }{}mx;

   chomp $value;
   $value =~ s{ [$chars]+ \z }{}mx;
   return $value;
}

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

sub uri_escape ($;$) {
   my ($v, $pattern) = @_; $pattern //= $uric;

   $v =~ s{([^$pattern])}{ URI::Escape::uri_escape_utf8($1) }ego;
   utf8::downgrade( $v );
   return $v;
}

sub maybe_render_partial ($) {
   my $context = shift;
   my $header  = $context->request->header('prefer') // q();

   return unless $header eq 'render=partial';

   if (my $exception = $context->stash('exception')) {
      $context->stash(redirect2referer $context, [$exception->original]);
      return;
   }

   my $page = $context->stash('page') // {};

   $page->{html} = 'none';
   $page->{wrapper} = 'none';
   $context->stash( page => $page );
   return;
}

sub _pseudo_random {
   return join q(), time, rand 10_000, $PID, {};
}

1;
