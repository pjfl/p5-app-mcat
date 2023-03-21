package MCat::Util;

use strictures;

use Ref::Util   qw( is_hashref );
use URI::Escape qw( );
use URI::http;
use URI::https;

use Sub::Exporter -setup => { exports => [
   qw( formpost local_tz new_uri redirect uri_escape )
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

1;
