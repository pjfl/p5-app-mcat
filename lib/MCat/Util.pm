package MCat::Util;

use strictures;

use Ref::Util   qw( is_hashref );
use URI::Escape qw( );
use URI::http;
use URI::https;

use Sub::Exporter -setup => { exports => [
   qw( action_path2uri new_uri redirect register_action_paths uri_escape )
]};

my $action_path_to_uri = {}; # Key is an action path, value a partial URI
my $reserved   = q(;/?:@&=+$,[]);
my $mark       = q(-_.!~*'());                                   #'; emacs
my $unreserved = "A-Za-z0-9\Q${mark}\E%\#";
my $uric       = quotemeta($reserved) . '\p{isAlpha}' . $unreserved;

sub action_path2uri ($;$) {
   return $action_path_to_uri->{$_[0]} unless defined $_[1];

   return $action_path_to_uri->{$_[0]} = $_[1];
}

sub new_uri ($$) {
   my $v = uri_escape($_[1]); return bless \$v, 'URI::'.$_[0];
}

sub redirect ($$) {
   return redirect => { location => $_[0], message => $_[1] };
}

sub register_action_paths (;@) {
   my $moniker = shift;
   my $args    = (is_hashref $_[0]) ? $_[0] : { @_ };

   for my $k (keys %{$args}) { action_path2uri("${moniker}/${k}", $args->{$k}) }

   return;
}

sub uri_escape ($;$) {
   my ($v, $pattern) = @_; $pattern //= $uric;

   $v =~ s{([^$pattern])}{ URI::Escape::uri_escape_utf8($1) }ego;
   utf8::downgrade( $v );
   return $v;
}

1;
