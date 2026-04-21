package MCat::Markdown;

use strictures;
use parent 'Text::MultiMarkdown';

=pod

=encoding utf-8

=head1 Name

MCat::Markdown - Markdown formatter

=head1 Synopsis

   use MCat::Markdown;

=head1 Description

Markdown formatter. A subclass of L<Text::MultiMarkdown> which adds support
for code blocks introduced by three grave characters followed by the
language name

=head1 Configuration and Environment

Defines no attributes

=head1 Subroutines/Methods

Defines no methods

=cut

sub _DoCodeBlocks { # Add support for triple graves
   my ($self, $text) = @_;

   $text =~ s{
         (?:```(.*)[ \n])
         ([^`]+)
         (?:[ \n]?```([^ \n]*)?)
      }{
      my $class = $1 || $3 || q();
      my $codeblock = $2;
      my $result;

      $codeblock = $self->_EncodeCode($self->_Outdent($codeblock));
      $codeblock = $self->_Detab($codeblock);
      $codeblock =~ s/\A\n+//;
      $codeblock =~ s/\n+\z//;
      $codeblock = $self->_H12Hash($codeblock);
      $class     = " class=\"${class}\"" if $class;
      $result    = "\n\n<pre><code${class}>${codeblock}\n</code></pre>\n\n";
      $result;
   }egmx;

   return $text;
}

sub _H12Hash {
   my ($self, $block) = @_;

   $block =~ s{ &lt; h1 [^\&]* &gt; }{\n# }mx;
   $block =~ s{ &lt; /h1 &gt; }{}mx;

   return $block;
}

1;

__END__

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Text::MultiMarkdown>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=MCat.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2025 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
