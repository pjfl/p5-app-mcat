package MCat::Schema::Admin;

use Archive::Tar::Constant      qw( COMPRESS_GZIP );
use Class::Usul::Cmd::Constants qw( AS_PARA AS_PASSWORD COMMA OK QUOTED_RE
                                    SECRET );
use HTML::Forms::Constants      qw( EXCEPTION_CLASS FALSE NUL SPC TRUE );
use Class::Usul::Cmd::Util      qw( decrypt encrypt ensure_class_loaded
                                    now_dt trim );
use File::DataClass::IO         qw( io );
use Unexpected::Functions       qw( throw PathNotFound Unspecified );
use Archive::Tar;
use Data::Record;
use File::DataClass::Schema;
use Format::Human::Bytes;
use Try::Tiny;
use Moo;
use Class::Usul::Cmd::Options;

extends 'Class::Usul::Cmd';
with    'MCat::Role::Config';
with    'MCat::Role::Log';

has 'admin_password' =>
   is      => 'lazy',
   default => sub {
      my $self     = shift;
      my $password = $self->get_line('+Enter DB admin password', AS_PASSWORD);

      throw 'No database admin password supplied' unless $password;

      return $ENV{PGPASSWORD} = $password;
   };

has 'config_extension' => is => 'ro', default => '.json';

has 'deploy_classes' => is => 'ro', default => sub { ['MCat::Schema'] };

has 'host' => is => 'ro', default => 'localhost';

has 'producers' =>
   is      => 'ro',
   default => sub {
      return { mysql => 'MySQL', pg => 'PostgreSQL', sqlite => 'SQLite' };
   };

has 'schema' =>
   is      => 'lazy',
   default => sub {
      my $self  = shift;
      my $class = $self->config->schema_class;
      my $info  = [ @{$self->config->connect_info} ];

      $info->[3] = _connect_attr();

      my $schema = $class->connect(@{$info});

      $class->config($self->config) if $class->can('config');

      return $schema;
   };

has 'user_password' =>
   is      => 'lazy',
   default => sub {
      my $self = shift;
      my $password = $self->_local_config->{db_password};

      throw 'No database user password in local config file' unless $password;

      return decrypt SECRET, $password;
   };

has '_file_schema' =>
   is      => 'lazy',
   default => sub { File::DataClass::Schema->new(storage_class => 'Any') };

has '_dbname' =>
   is      => 'lazy',
   default => sub {
      my $self = shift;
      my $dbname;

      if ($self->config->dsn =~ m{ dbname[=] }mx) {
         $dbname = (map  { s{ \A dbname [=] }{}mx; $_ }
                    grep { m{ \A dbname [=] }mx }
                    split  m{           [:] }mx, $self->config->dsn)[0];
      }

      return $dbname;
   };

has '_ddl_path' =>
   is      => 'lazy',
   default => sub {
      my $self    = shift;
      my $schema  = $self->schema;
      my $type    = $self->_type;
      my $version = $schema->schema_version;
      my $dir     = $self->config->sqldir;

      return io($schema->ddl_filename($type, $version, $dir));
   };

has '_driver' =>
   is      => 'lazy',
   default => sub {
      my $self   = shift;
      my $driver = (split m{ : }mx, $self->config->dsn)[1];

      return lc $driver;
   };

has '_host' =>
   is      => 'lazy',
   default => sub {
      my $self = shift;
      my $host = $self->host;

      unless ($self->options && $self->options->{bootstrap}) {
         if ($self->config->dsn =~ m{ host[=] }mx) {
            $host = (map  { s{ \A host [=] }{}mx; $_ }
                     grep { m{ \A host [=] }mx }
                     split  m{         [;] }mx, $self->config->dsn)[0];
         }
      }

      return $host;
   };

has '_type' =>
   is      => 'lazy',
   default => sub {
      my $self = shift;

      return $self->producers->{$self->_driver};
   };

sub BUILD {}

=item backup - Backs up the database

Backs up the database

=cut

sub backup : method {
   my $self = shift;
   my $now  = now_dt;
   my $db   = $self->_dbname;
   my $date = $now->ymd(NUL).'-'.$now->hms(NUL);
   my $file = "${db}-${date}.sql";
   my $conf = $self->config;
   my $path = $conf->tempdir->catfile($file);
   my $bdir = $conf->vardir->catdir('backup');
   my $tarb = "${db}-${date}.tgz";
   my $out  = $bdir->catfile($tarb)->assert_filepath;
   my $opts = { args => [$tarb], name => 'Admin.backup' };

   ensure_class_loaded 'Archive::Tar';
   $self->info('Generating backup [_1]', $opts);
   $self->_create_ddl_file;
   $self->run_cmd($self->_backup_command($path));
   chdir $conf->home;

   my $arc = Archive::Tar->new;

   $self->_add_backup_files($arc);

   $arc->add_files($path->abs2rel($conf->home)) if $path->exists;

   $arc->write($out->pathname, COMPRESS_GZIP);
   $path->unlink;
   $file = $out->basename;

   my $size = Format::Human::Bytes->new()->base2($out->stat->{size});

   $opts = { args => [$file, $size], name => 'Admin.backup' };
   $self->info('Backup complete. File [_1] size [_2]', $opts);
   return OK;
}

=item install - Creates the MCat database and deploys the schema

Creates the MCat database and deploys the schema

=cut

sub install : method {
   my $self = shift;
   my $text = 'Schema creation requires a database, id and password. '
            . 'For Postgres the driver is Pg and the port 5432. For '
            . 'MySQL the driver is mysql and the port 3306';

   $self->output($text, AS_PARA);
   $self->yorn('+Create database', TRUE, TRUE, 0) or return OK;
   $self->admin_password;
   $self->store_password;
   $self->_drop_database;
   $self->_drop_user;
   $self->_create_user;
   $self->_create_database;
   $self->_deploy_and_populate_classes;
   return OK;
}

=item restore - Restores the database from a backup

Restores the database from a backup

=cut

sub restore : method {
   my $self = shift;
   my $conf = $self->config;
   my $path = $self->next_argv or throw Unspecified, ['file name'];

   $path = io $path;
   throw PathNotFound, [$path] unless $path->exists;
   ensure_class_loaded 'Archive::Tar';

   my $arc = Archive::Tar->new;

   chdir $conf->home;
   $arc->read($path->pathname);
   $arc->extract();

   my $db   = $self->_dbname;
   my $file = $path->basename('.tgz');
   my (undef, $date) = split m{ - }mx, $file, 2;
   my $sql  = $conf->tempdir->catfile("${db}-${date}.sql");

   if ($sql->exists) {
      $self->run_cmd($self->_restore_command($sql));
      $sql->unlink;
   }

   my $ver = $self->schema->get_db_version;

   $self->info('Restored backup [_1] schema [_1]', {
      args => [$file, $ver], name => 'Admin.restore'
   });

   return OK;
}

=item store_password - Stores the application users database password

It will write an encrypted copy of the database password to the local
configuration file

=cut

sub store_password : method {
   my $self     = shift;
   my $password = $self->get_line('+Enter DB user password', AS_PASSWORD);
   my $data     = $self->_local_config;

   $data->{db_password} = encrypt SECRET, $password;
   $self->_local_config($data);
   $self->info('Updated user password', { name => 'Admin.store_password' });
   return OK;
}

# Private functions
sub _connect_attr () {
   return {
      AutoCommit        => TRUE,
      PrintError        => FALSE,
      RaiseError        => TRUE,
      add_drop_table    => TRUE,
      ignore_version    => TRUE,
      no_comments       => TRUE,
      quote_identifiers => TRUE,
   };
}

sub _distname (;$) {
   (my $v = $_[0] // NUL) =~ s{ :: }{-}gmx; return $v;
}

sub _unquote ($) {
   local $_ = $_[0]; s{ \A [\'\"] }{}mx; s{ [\'\"] \z }{}mx; return $_;
}

# Private methods
sub _add_backup_files {
   my ($self, $arc) = @_;

   my $conf = $self->config;

   for my $file (map { io $_ } $conf->local_config_file) {
      $arc->add_files($file->abs2rel($conf->home));
   }

   $arc->add_files($self->_ddl_path->abs2rel($conf->home));
   return;
}

sub _backup_command {
   my ($self, $path) = @_;

   my $dbname = $self->_dbname;
   my $host   = $self->_host;
   my $user   = $self->config->db_username;
   my $driver = $self->_driver;
   my $cmd;

   if ($driver eq 'pg') {
      $ENV{PGPASSWORD} = $self->user_password;
      $cmd = "pg_dump --file=${path} -h ${host} -U ${user} ${dbname}";
   }

   throw 'No backup command for driver [_1]', [$driver] unless $cmd;

   return $cmd;
}

sub _create_database {
   my $self   = shift;
   my $dbname = $self->_dbname;
   my $host   = $self->_host;
   my $user   = $self->config->db_username;
   my $driver = $self->_driver;
   my $cmd;

   if ($driver eq 'pg') {
      $cmd = "psql -h ${host} -q -t -U postgres -w -c "
           . "\"create database ${dbname} owner ${user} encoding 'UTF8';\"";
   }

   throw 'No create database command for driver [_1]', [$driver] unless $cmd;

   return $self->run_cmd($cmd, { out => 'stdout' });
}

sub _create_ddl_file {
   my $self    = shift;
   my $schema  = $self->schema;
   my $type    = $self->_type;
   my $version = $schema->schema_version;
   my $dir     = $self->config->sqldir;

   $schema->create_ddl_dir($type, $version, $dir);
   return;
}

sub _create_user {
   my $self    = shift;
   my $host    = $self->_host;
   my $dbname  = $self->_dbname;
   my $user    = $self->config->db_username;
   my $upasswd = $self->user_password;
   my $driver  = $self->_driver;
   my $cmd;

   if ($driver eq 'pg') {
      $cmd = "psql -h ${host} -q -t -U postgres -w -c "
           . "\"create role ${user} login password '${upasswd}';\"";
   }

   throw 'No create user command for driver [_1]', [$driver] unless $cmd;

   return $self->run_cmd($cmd, { out => 'stdout' });
}

sub _deploy_and_populate_classes {
   my $self = shift;
   my $dir  = $self->config->sqldir;

   my $result_objects;

   for my $schema_class (@{$self->deploy_classes}) {
      $self->info('Deploy and populate [_1]', {
         args => [$schema_class], name => 'Admin.deploy' }
      );
      $self->yorn('+Continue', TRUE, TRUE, 0) or next;
      ensure_class_loaded $schema_class;
      $schema_class->config($self->config) if $schema_class->can('config');
      $self->info('Deploying schema [_1] and populating', {
         args => [$schema_class], name => 'Admin.deploy' }
      );
      $result_objects = $self->_deploy_and_populate($schema_class, $dir);
   }

   return;
}

sub _deploy_and_populate {
   my ($self, $schema_class, $dir) = @_;

   my $schema = $self->schema;

   $schema->storage->ensure_connected;
   $schema->deploy(_connect_attr, $dir);

   my $split = Data::Record->new({ split => COMMA, unless => QUOTED_RE });
   my $res;

   for my $tuple (@{$self->_list_population_classes($schema_class, $dir)}) {
      $res->{$tuple->[0]} = $self->_populate_class($schema, $split, @{$tuple});
   }

   return $res;
}

sub _drop_database {
   my $self   = shift;
   my $dbname = $self->_dbname;
   my $host   = $self->_host;
   my $driver = $self->_driver;
   my $cmd;

   if ($driver eq 'pg') {
      $cmd = "psql -h ${host} -q -t -U postgres -w -c "
           . "\"drop database if exists ${dbname};\"";
   }

   throw 'No drop database command for driver [_1]', [$driver] unless $cmd;

   return $self->run_cmd($cmd, { out => 'stdout' });
}

sub _drop_user {
   my $self   = shift;
   my $host   = $self->_host;
   my $user   = $self->config->db_username;
   my $driver = $self->_driver;
   my $cmd;

   if ($driver eq 'pg') {
      $cmd = "psql -h ${host} -q -t -U postgres -w -c "
           . "\"drop user if exists ${user};\"";
   }

   throw 'No drop user command for driver [_1]', [$driver] unless $cmd;

   my $output = $self->run_cmd($cmd, { expected_rv => 1, out => 'buffer' });

   $self->dumper($output) if $self->debug;
   return;
}

sub _list_population_classes {
   my ($self, $schema_class, $dir) = @_;

   my $dist = _distname $schema_class;
   my $extn = $self->config_extension;
   my $re   = qr{ \A $dist [-] \d+ [-] (.*) \Q$extn\E \z }mx;
   my $io   = io($dir)->filter(sub { $_->filename =~ $re });
   my $res  = [];

   for my $path ($io->all_files) {
      my ($class) = $path->filename =~ $re;

      push @{$res}, [$class, $path];
   }

   return $res;
}

sub _local_config {
   my ($self, $data) = @_;

   throw 'Local config file undefined'
      unless $self->config->has_local_config_file;

   my $file = $self->config->local_config_file;

   if ($data) {
      $self->_file_schema->dump({ path => $file->assert, data => $data });
      return $data;
   }

   return $self->_file_schema->load($file) // {} if $file->exists;

   return {};
}

sub _populate_class {
   my ($self, $schema, $split, $class, $path) = @_;

   unless ($class) {
      $self->fatal('No class in [_1]', {
         args => [$path->filename], name => 'Admin._populate_class'
      });
   }

   $self->output("Populating ${class}");

   my $data   = $self->_file_schema->data_load(paths => [$path]) // {};
   my $fields = [split SPC, $data->{fields}];
   my @rows   = map { [ map { _unquote(trim $_) } $split->records($_) ] }
                   @{ $data->{rows} };
   my $res;

   try   { $res = $schema->populate($class, [$fields, @rows]) }
   catch {
      if ($_->can('class') and $_->class eq 'ValidationErrors') {
         $self->warning("${_}") for (@{$_->args});
      }

      throw $_;
   };

   return $res;
}

sub _restore_command {
   my ($self, $sql) = @_;

   my $host   = $self->_host;
   my $user   = $self->config->db_username;
   my $driver = $self->_driver;
   my $cmd;

   if ($driver eq 'pg') {
      $ENV{PGPASSWORD} = $self->user_password;
      $cmd = "pg_restore -C -d postgres -h ${host} -U ${user} ${sql}";
   }

   throw 'No restore command for driver [_1]', [$driver] unless $cmd;

   return $cmd;
}

use namespace::autoclean;

1;
