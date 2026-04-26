package MCat::File::Docs::View;

use MCat::Constants qw( FALSE TRUE );
use URI::Escape     qw( uri_escape uri_unescape );
use MCat::Markdown;
use Pod::Markdown::Github;
use Moo;

has 'local_docs' =>
   is      => 'ro',
   default => sub {
      return [
         qw(App::Burp App::Job Class::Usul::Cmd HTML::Forms HTML::StateTable
            MCat Web::Components Web::ComposableRequest)
      ];
   };

has 'remote_pattern' => is => 'ro', default => 'https://metacpan\.org/pod/';

sub get {
   my ($self, $context, $path) = @_;

   my $parser = Pod::Markdown::Github->new;

   $parser->output_string(\my $markdown);
   $parser->parse_file($path->as_string);

   $markdown =~ s{ \\ }{}gmx;
   $markdown =~ s{ [ ]_(\w+) }{ $1}gmx;

   return '<h1>Nothing Found</h1>' unless length $markdown > 2;

   for my $package (@{$self->local_docs}) {
      my $remote = $self->remote_pattern . uri_escape($package);

      $markdown =~ s{ \(($remote[^\)]*)\) }{_substitute($self,$context,$1)}gemx;
   }

   my $formatter = MCat::Markdown->new();

   return $formatter->markdown($markdown);
}

# Private methods
sub _substitute {
   my ($self, $context, $remote) = @_;

   my $pattern = $self->remote_pattern;

   return "(${remote})" unless $remote =~ m{ $pattern }mx;

   $remote =~ s{ $pattern }{}mx;

   my @parts    = split m{ :: }mx, uri_unescape($remote);
   my $selected = pop @parts;
   my $dir      = join '!', @parts;
   my $query    = { directory => $dir, selected => "${selected}.pm" };
   my $actionp  = (!$dir || $dir =~ m{ \A MCat }mx)
                ? 'doc/application' : 'doc/server';
   my $uri      = $context->uri_for_action($actionp, [], $query);

   return "(${uri})";
}

use namespace::autoclean;

1;
