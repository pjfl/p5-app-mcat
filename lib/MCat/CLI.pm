package MCat::CLI;

use MCat;
use Class::Usul::Constants qw( AS_PASSWORD OK );
use Class::Usul::File;
use Class::Usul::Functions qw( base64_encode_ns );
use HTML::Forms::Util      qw( cipher );
use Moo;
use Class::Usul::Options;

extends q(Class::Usul);
with    q(Class::Usul::TraitFor::OutputLogging);
with    q(Class::Usul::TraitFor::Prompting);
with    q(Class::Usul::TraitFor::Usage);
with    q(Class::Usul::TraitFor::RunningMethods);

has '+config_class' => default => 'MCat::Config';

=head1 Subroutines/Methods

=over 3

=cut

sub BUILD {}

=item set_db_password - Sets the database password

Run this before attempting to start the application. It will write an
encrypted copy of the database password to the local configuration file

=cut

sub set_db_password : method {
   my $self     = shift;
   my $fclass   = 'Class::Usul::File';
   my $file     = $self->config->local_config_file;
   my $data     = $fclass->data_load( paths => [$file] ) // {} if $file->exists;
   my $password = $self->get_line('+Enter DB password', AS_PASSWORD);

   $data->{db_password} = base64_encode_ns cipher->encrypt($password);
   $fclass->data_dump({ path => $file->assert, data => $data });
   return OK;
}

use namespace::autoclean;

1;

__END__

=back
