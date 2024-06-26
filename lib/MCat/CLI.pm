package MCat::CLI;

use MCat;
use MCat::Exception;
use Class::Usul::Cmd::Constants qw( FALSE NUL OK TRUE );
use HTML::Forms::Constants      qw( EXCEPTION_CLASS );
use File::DataClass::Types      qw( Directory );
use Class::Usul::Cmd::Util      qw( ensure_class_loaded );
use English                     qw( -no_match_vars );
use File::DataClass::IO         qw( io );
use JSON::MaybeXS               qw( decode_json );
use Type::Utils                 qw( class_type );
use Unexpected::Functions       qw( throw UnknownImport Unspecified );
use MCat::Markdown;
use MCat::Redis;
use Moo;
use Class::Usul::Cmd::Options;

extends 'Class::Usul::Cmd';
with    'MCat::Role::Config';
with    'MCat::Role::Log';
with    'MCat::Role::Schema';
with    'Web::Components::Role::Email';

has 'assetdir' =>
   is      => 'lazy',
   isa     => Directory,
   default => sub { $_[0]->config->root->catdir('img') };

has 'formatter' =>
   is      => 'lazy',
   isa     => class_type('MCat::Markdown'),
   default => sub { MCat::Markdown->new( tab_width => 3 ) };

has 'redis' =>
   is      => 'lazy',
   isa     => class_type('MCat::Redis'),
   default => sub {
      my $self = shift;

      return MCat::Redis->new(
         client_name => $self->config->prefix . '_job_stash',
         config => $self->config->redis
      );
   };

has 'templatedir' =>
   is      => 'lazy',
   isa     => Directory,
   default => sub {
      my $self = shift;

      return $self->config->vardir->catdir(
         'templates', $self->config->skin, 'site', 'email'
      );
   };

=head1 Subroutines/Methods

=over 3

=cut

sub BUILD {}

=item import_file - Imports a CSV file into the selected table

Uses the import id provided to determine the selected table, the import
file, and the import mapping

=cut

sub import_file: method {
   my $self    = shift;
   my $guid    = $self->options->{guid} or throw Unspecified, ['guid'];
   my $id      = $self->options->{id} or throw Unspecified, ['id'];
   my $user_id = $self->options->{user_id} or throw Unspecified, ['user_id'];
   my $rs      = $self->schema->resultset('Import');
   my $import  = $rs->find($id) or throw UnknownImport, [$id];
   my $result  = $import->process($id, $guid, $user_id);
   my $options = { name => 'CLI.import_file' };
   my $count   = $result->{count};

   $self->info("Imported ${count} records. Import guid ${guid}", $options);

   if ($count = scalar @{$result->{warnings}}) {
      $self->warning("Failed ${count} records", $options);
      $self->warning('First error - ' . $result->{warnings}->[0], $options);
   }

   return OK;
}

=item install - Creates directories and starts schema installation

Creates directories and starts schema installation. Needs to run before
the schema admin program creates the database so that the config object
sees the right directories

=cut

sub install : method {
   my $self = shift;

   for my $dir (qw( backup log tmp )) {
      my $path = $self->config->vardir->catdir($dir);

      $path->mkpath(oct '0770') unless $path->exists;
   }

   my $path = $self->config->root->catdir('file');

   $path->mkpath(oct '0770') unless $path->exists;

   $self->_create_profile;

   my $cmd = $self->config->bin->catfile('mcat-schema');

   $self->_install_schema($cmd) if $cmd->exists;

   return OK;
}

=item make_css - Make concatenated CSS file

Run automatically if L<App::Burp> is running. It concatenates multiple CSS files
into a single one

=cut

sub make_css : method {
   my $self  = shift;
   my $dir   = io['share', 'css'];
   my @files = ();

   $dir->filter(sub { m{ \.css \z }mx })->visit(sub { push @files, shift });

   my $skin  = $self->config->skin;
   my $file  = "mcat-${skin}.css";
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
   ensure_class_loaded('CSS::LESS');

   my $file  = 'mcat.css';
   my $out   = io([qw( share css ), $file])->assert_open('a')->truncate(0);
   my $count =()= map  { $out->append(CSS::LESS->new()->compile($_->all)) }
                  sort { $a->name cmp $b->name } @files;
   my $options = { name => 'CLI.make_less' };

   $self->info("Concatenated ${count} files to ${file}", $options);
   return OK;
}

=item send_message - Send a message

=cut

sub send_message : method {
   my $self     = shift;
   my $options  = $self->options;
   my $sink     = $self->next_argv or throw Unspecified, ['message sink'];
   my $quote    = $self->next_argv ? TRUE : $options->{quote} ? TRUE : FALSE;
   my $stash    = $self->_load_stash($quote);
   my $attaches = $self->_qualify_assets(delete $stash->{attachments});
   my $log_opts = { name => 'CLI.send_message' };

   if ($sink eq 'email') {
      my $recipients = delete $stash->{recipients};
      my $rs = $self->schema->resultset('User');

      for my $id_or_email (@{$recipients // []}) {
         if ($id_or_email =~ m{ \A \d+ \z }mx) {
            my $user = $rs->find($id_or_email);

            unless ($user) {
               $self->error("User ${id_or_email} unknown", $log_opts);
               next;
            }

            unless ($user->can_email) {
               $self->error("User ${user} bad email address", $log_opts);
               next;
            }

            $stash->{email} = $user->email;
            $stash->{username} = "${user}";
         }
         else { $stash->{email} = $id_or_email }

         $self->_send_email($stash, $attaches);
      }
   }
   elsif ($sink eq 'sms') { $self->_send_sms($stash) }
   else { throw 'Message sink [_1] unknown', [$sink] }

   return OK;
}

=item update_list - Updates list using a filter

=cut

sub update_list : method {
   my $self      = shift;
   my $list_id   = $self->options->{list_id};
   my $filter_id = $self->options->{filter_id};
   my $list      = $self->schema->resultset('List')->find($list_id);
   my $filter    = $self->schema->resultset('Filter')->find($filter_id);
   my $count     = $list->apply_filter($filter);
   my $options   = { name => 'CLI.update_list' };
   my $name      = $list->name;

   $self->output("Added ${count} entries to ${name} list", $options);
   return OK;
}

# Private methods
sub _create_profile {
   my $self = shift;

   $self->output('Env var PERL5LIB is '.$ENV{PERL5LIB});
   $self->yorn('+Is this correct', FALSE, TRUE, 0) or return;
   $self->output('Env var PERL_LOCAL_LIB_ROOT is '.$ENV{PERL_LOCAL_LIB_ROOT});
   $self->yorn('+Is this correct', FALSE, TRUE, 0) or return;

   my $localdir = $self->config->home->catdir('local');
   my $profile;

   if ($localdir->exists) {
      $profile = $localdir->catfile(qw( var etc mcat-profile ));
   }
   elsif ($localdir = io['~', 'local'] and $localdir->exists) {
      $profile = $self->config->vardir->catfile('etc', 'mcat-profile');
   }
   elsif ($localdir = io($ENV{PERL_LOCAL_LIB_ROOT} // NUL)
          and $localdir->exists) {
      $profile = $self->config->vardir->catfile('etc', 'mcat-profile');
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

sub _install_schema {
   my ($self, $cmd) = @_;

   my $opts = { err => 'stderr', in => 'stdin', out => 'stdout' };

   $self->run_cmd([$cmd, '-o', 'bootstrap=1', 'install'], $opts);
   return;
}

sub _load_stash {
   my ($self, $quote) = @_;

   my $token    = $self->options->{token} or throw Unspecified, ['token'];
   my $encoded  = $self->redis->get($token)
      or throw 'Token [_1] not found', [$token];
   my $stash    = decode_json($encoded);
   my $template = delete $stash->{template};
   my $path     = $self->templatedir->catfile($template);

   $path = io $template unless $path->exists;

   $stash->{content} = $path->all;
   $stash->{content} = $self->formatter->markdown($stash->{content})
      if $template =~ m{ \.md \z }mx;

   my $tempdir  = $self->config->tempdir;

   unlink $template if $tempdir eq substr $template, 0, length $tempdir;

   $stash->{quote} = $quote;
   return $stash;
}

sub _qualify_assets {
   my ($self, $files) = @_;

   return FALSE unless $files;

   my $assets = {};

   for my $file (@{$files}) {
      my $path = $self->assetdir->catfile($file);

      $path = io $file unless $path->exists;

      next unless $path->exists;

      $assets->{$path->basename} = $path;
   }

   return $assets;
}

sub _send_email {
   my ($self, $stash, $attaches) = @_;

   my $content  = $stash->{content};
   my $wrapper  = $self->config->skin . '/site/wrapper/email.tt';
   my $template = "[% WRAPPER '${wrapper}' %]${content}[% END %]";
   my $post     = {
      attributes      => {
         charset      => $self->config->encoding,
         content_type => 'text/html',
      },
      from            => $self->config->name,
      stash           => $stash,
      subject         => $stash->{subject} // 'No subject',
      template        => \$template,
      to              => $stash->{email},
   };

   $post->{attachments} = $attaches if $attaches;

   my ($id)    = $self->send_email($post);
   my $options = { args => [$stash->{email}, $id], name => 'CLI.send_message' };

   $self->info('Emailed [_1] message id. [_2]', $options);
   return;
}

sub _send_sms { ... }

use namespace::autoclean;

1;

__END__

=back
