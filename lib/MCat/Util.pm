package MCat::Util;

use strictures;

use Ref::Util   qw( is_hashref );
use URI::Escape qw( );
use URI::http;
use URI::https;

use Sub::Exporter -setup => { exports => [
   qw( formpost local_tz maybe_render_partial new_uri redirect uri_escape )
]};

my $reserved   = q(;/?:@&=+$,[]);
my $mark       = q(-_.!~*'());                                   #'; emacs
my $unreserved = "A-Za-z0-9\Q${mark}\E%\#";
my $uric       = quotemeta($reserved) . '\p{isAlpha}' . $unreserved;

sub formpost () {
   return { method => 'post' };
}

sub local_tz () {
   return 'Europe/London';
}

sub new_uri ($$) {
   my $v = uri_escape($_[1]); return bless \$v, 'URI::'.$_[0];
}

sub redirect ($$) {
   return redirect => { location => $_[0], message => $_[1] };
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
      my $referer = new_uri 'http', $context->request->referer;

      $context->stash( redirect $referer, [$exception->original] );
      return;
   }

   my $page = $context->stash('page') // {};

   $page->{html} = 'none';
   $page->{wrapper} = 'none';
   $context->stash( page => $page );
   return;
}

1;
