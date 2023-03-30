package MCat::CLI;

use MCat;
use Class::Usul::Constants     qw( AS_PASSWORD FALSE NUL OK TRUE );
use Class::Usul::File;
use Class::Usul::Functions     qw( base64_encode_ns emit );
use English                    qw( -no_match_vars );
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

sub post_install : method {
   my $self     = shift;
   my $conf     = $self->config;
   my $localdir = $conf->home->catdir('local');

   $self->_check_env_vars;

   for my $dir (qw( backup log tmp )) {
      my $path = $localdir->exists
         ? $localdir->catdir('var', $dir) : $conf->vardir->catdir($dir);

      $path->mkpath(oct '0770') unless $path->exists;
   }

   $self->_create_profile($localdir);

   my $cmd = $conf->binsdir->catfile('mcat-schema');

   $self->_deploy_schema($cmd) if $cmd->exists;

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

# Private methods
sub _check_env_vars {
   my $self = shift;

   $self->output('Env var PERL5LIB is '.$ENV{PERL5LIB});
   $self->yorn('+Is this correct', FALSE, TRUE, 0) or return;
   $self->output('Env var PERL_LOCAL_LIB_ROOT is '.$ENV{PERL_LOCAL_LIB_ROOT});
   $self->yorn('+Is this correct', FALSE, TRUE, 0) or return;
   return;
}

sub _create_profile {
   my ($self, $localdir) = @_;

   my $profile;

   if ($localdir->exists) {
      $profile = $localdir->catfile(qw( var etc profile ));
   }
   elsif ($localdir = io['~', 'local'] and $localdir->exists) {
      $profile = $self->config->vardir->catfile('etc', 'profile');
   }
   elsif ($localdir = io($ENV{PERL_LOCAL_LIB_ROOT} // NUL)
          and $localdir->exists) {
      $profile = $self->config->vardir->catfile('etc', 'profile');
   }

   return if !$profile || $profile->exists;

   my $inc     = $localdir->catdir('lib', 'perl5');
   my $cmd     = [$EXECUTABLE_NAME, '-I', "${inc}", "-Mlocal::lib=${localdir}"];
   my $p5lib   = delete $ENV{PERL5LIB};
   my $libroot = delete $ENV{PERL_LOCAL_LIB_ROOT};

   $self->run_cmd($cmd, { err => 'stderr', out => $profile });
   $ENV{PERL5LIB} = $p5lib;
   $ENV{PERL_LOCAL_LIB_ROOT} = $libroot;
   return;
}

sub _deploy_schema {
   my ($self, $cmd) = @_;

   my $opts = { err => 'stderr', in => 'stdin', out => 'stdout' };

   # TODO: Add -a option to create the usertable schema also
   $self->run_cmd([$cmd, '-o', 'bootstrap=1', 'deploy'], $opts);
   return;
}

use namespace::autoclean;

1;

__END__

=back
