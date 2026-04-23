package MCat::Authentication::Realms::Google;

use MCat::Util   qw( create_token );
use MIME::Base64 qw( decode_base64url );
use Moo;

extends 'MCat::Authentication::Realms::OAuth';

=pod

=encoding utf-8

=head1 Name

MCat::Authentication::Realms::Google - Authenticate with Google

=head1 Synopsis

   use MCat::Authentication::Realms::Google;

=head1 Description

Authenticate with Google as the OAuth provider

=head1 Configuration and Environment

Defines no attributes

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item C<redirect_params>

Add Google specific attributes to the hash reference returned by the
method in the parent class

=cut

around 'redirect_params' => sub {
   my ($orig, $self, $state) = @_;

   my $params = $orig->($self, $state);

   $params->{nonce}         = substr create_token, 0, 12;
   $params->{response_type} = 'code';
   $params->{scope}         = 'openid email';

   return $params;
};

=item C<token_params>

Add Google specific attributes to the hash reference returned by the
method in the parent class

=cut

around 'token_params' => sub {
   my ($orig, $self, $code) = @_;

   my $params = $orig->($self, $code);

   $params->{grant_type} = 'authorization_code';

   return $params;
};

=item C<decode_tokens>

Decodes tokens Google style

=cut

sub decode_tokens {
   my ($self, $content) = @_;

   return $self->json_parser->decode($content);
}

=item C<get_claim>

Google provides the user claim as a separate token along with the
C<access_token>. Decode and return that claim

=cut

sub get_claim {
   my ($self, $tokens) = @_;

   return {} unless $tokens && $tokens->{id_token};

   my ($header, $claim, $crypt) = split m{ \. }mx, $tokens->{id_token};

   return $self->json_parser->decode(decode_base64url($claim));
}

use namespace::autoclean;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<MCat::Authentication::Realms::OAuth>

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
