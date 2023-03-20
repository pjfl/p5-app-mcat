package MCat::CLI;

use MCat;
use Class::Usul::Constants     qw( AS_PASSWORD OK );
use Class::Usul::File;
use Class::Usul::Functions     qw( base64_encode_ns emit );
use File::DataClass::Functions qw( ensure_class_loaded );
use File::DataClass::IO        qw( io );
use HTML::Forms::Util          qw( cipher );
use Moo;
use Class::Usul::Options;

extends q(Class::Usul);
with    q(Class::Usul::TraitFor::OutputLogging);
with    q(Class::Usul::TraitFor::Prompting);
with    q(Class::Usul::TraitFor::Usage);
with    q(Class::Usul::TraitFor::RunningMethods);

has '+config_class' => default => 'MCat::Config';

has '+log_class' => default => 'MCat::Log';

=head1 Subroutines/Methods

=over 3

=cut

sub BUILD {}

=item make_css - Make concatenated CSS file

Run automatically if L<App::Burp> is running. It concatenates multiple CSS files
into a single one

=cut

sub make_css : method {
   my $self  = shift;
   my $dir   = io['share', 'css'];
   my @files = ();

   $dir->filter(sub { m{ \.css \z }mx })->visit(sub { push @files, shift });

   my $file  = 'mcat.css';
   my $out   = io([qw( var root css ), $file])->assert_open('a')->truncate(0);
   my $count =()= map  { $out->append($_->slurp) }
                  sort { $a->name cmp $b->name } @files;
   my $options = { name => 'CLI.make_css' };

   $self->info("Concatenated ${count} files to ${file}", $options);
   return OK;
}

=item make_js - Make concatenated JS file

Run automatically if L<App::Burp> is running. It concatenates multiple JS files
into a single one

=cut

sub make_js : method {
   my $self  = shift;
   my $dir   = io['share', 'js'];
   my @files = ();

   $dir->filter(sub { m{ \.js \z }mx })->visit(sub { push @files, shift });

   my $file  = 'mcat.js';
   my $out   = io([qw( var root js ), $file])->assert_open('a')->truncate(0);
   my $count =()= map  { $out->append($_->slurp) }
                  sort { $a->name cmp $b->name } @files;
   my $options = { name => 'CLI.make_js' };

   $self->info("Concatenated ${count} files to ${file}", $options);
   return OK;
}

=item make_less - Convert LESS files to CSS

=cut

sub make_less : method {
   my $self  = shift;
   my $dir   = io['share', 'less'];
   my @files = ();

   $dir->filter(sub { m{ \.less \z }mx })->visit(sub { push @files, shift });
   ensure_class_loaded('CSS::LESSp');

   my $file  = 'mcat.css';
   my $out   = io([qw( share css ), $file])->assert_open('a')->truncate(0);
   my $count =()= map  { $out->append(CSS::LESSp->parse($_->all)) }
                  sort { $a->name cmp $b->name } @files;
   my $options = { name => 'CLI.make_less' };

   $self->info("Concatenated ${count} files to ${file}", $options);
   return OK;
}

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
   $self->info('Updated database password', { name => 'CLI.set_db_password' });
   return OK;
}

use namespace::autoclean;

1;

__END__

=back
