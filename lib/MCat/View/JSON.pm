package MCat::View::JSON;

use JSON::MaybeXS qw( encode_json );
use Moo;

with 'Web::Components::Role';

has '+moniker' => default => 'json';

sub serialize {
   my ($self, $context) = @_;

   my $stash = $context->stash;
   my $json  = $stash->{body} if $stash->{body};

   $json = encode_json $stash->{json} unless $json;

   return [ $stash->{code}, _header($stash->{http_headers}), [$json] ];
}

sub _header {
   return [ 'Content-Type'  => 'application/json', @{ $_[0] // [] } ];
}

use namespace::autoclean;

1;
