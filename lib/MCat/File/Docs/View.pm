package MCat::File::Docs::View;

use MCat::Markdown;
use HTML::Tiny;
use Pod::Markdown::Github;
use Moo;

has '_html' => is => 'ro', default => sub { HTML::Tiny->new };

sub get {
   my ($self, $path) = @_;

   my $parser = Pod::Markdown::Github->new;

   $parser->output_string(\my $markdown);
   $parser->parse_file($path->as_string);

   my $formatter = MCat::Markdown->new();

   return $formatter->markdown($markdown);
}

use namespace::autoclean;

1;
