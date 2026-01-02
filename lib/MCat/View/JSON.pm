package MCat::View::JSON;

use Moo;

with 'Web::Components::Role';
with 'MCat::Role::JSONParser';

has '+moniker' => default => 'json';

sub serialize {
   my ($self, $context) = @_;

   my $stash = $context->stash;
   my $json; $json = $stash->{body} if $stash->{body};

   $json = $self->json_parser->encode($stash->{json}) unless $json;

   return [ $stash->{code}, _header($stash->{http_headers}), [$json] ];
}

sub _header {
   return [ 'Content-Type' => 'application/json', @{ $_[0] // [] } ];
}

use namespace::autoclean;

1;
