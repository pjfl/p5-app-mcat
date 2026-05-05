package MCat::File::Docs::View;

use MCat::Markdown;
use Pod::Markdown::Github;
use Moo;

sub get {
   my ($self, $context, $path) = @_;

   my $parser = Pod::Markdown::Github->new;

   $parser->output_string(\my $markdown);
   $parser->parse_file($path->as_string);

   my $formatter = MCat::Markdown->new( tab_width => 3 );

   $markdown = $formatter->localise_markdown($context, $markdown);

   return $formatter->markdown($markdown);
}

use namespace::autoclean;

1;
