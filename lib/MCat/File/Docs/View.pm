package MCat::File::Docs::View;

use MCat::Markdown;
use Pod::Markdown::Github;
use Moo;

sub get {
   my ($self, $path) = @_;

   my $parser = Pod::Markdown::Github->new;

   $parser->output_string(\my $markdown);
   $parser->parse_file($path->as_string);

   my $formatter = MCat::Markdown->new();

   $markdown =~ s{\\}{}gmx;

   $markdown = 'Nothing found' if length $markdown < 2;

   return $formatter->markdown($markdown);
}

use namespace::autoclean;

1;
