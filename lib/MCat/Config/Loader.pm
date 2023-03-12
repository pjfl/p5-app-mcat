package MCat::Config::Loader;

use File::DataClass::IO    qw( io );
use File::DataClass::Types qw( Directory File );
use File::DataClass::Schema;
use Moo::Role;

has 'config_file' => is => 'ro', isa => File, predicate => 'has_config_file';

has 'config_home' => is => 'ro', isa => Directory,
   predicate => 'has_config_home';

has 'home' => is => 'ro', isa => Directory;

has 'local_config_file' => is => 'ro', isa => File,
   predicate => 'has_local_config_file';

sub config_file_list ($) {
   my $attr       = shift;
   my $appclass   = $attr->{appclass};
   my $key        = uc "${appclass}_config";
   my $file       = $attr->{config_file} // $ENV{$key} // lc $appclass;
   my $extensions = $attr->{config_extensions} // 'json yaml';

   return map { "${file}.${_}" } split m{ \s }mx, $extensions;
}

sub dist_indicator_file_list () {
   return qw( Makefile.PL Build.PL dist.ini cpanfile );
}

sub find_config ($) {
   my $attr = shift;
   my $home = $attr->{home};

   my ($config_home, $config_file);

   for my $dir ($home->catdir('var', 'etc'), $home->catdir('etc'), $home) {
      for my $file (config_file_list $attr) {
         if ($dir->catfile($file)->exists) {
            $config_home = $dir;
            $config_file = $dir->catfile($file);
            last;
         }
      }

      last if $config_file;
   }

   return ($config_home, $config_file);
}

sub find_home ($) {
   my $attr  = shift;
   my $class = $attr->{appclass};
   (my $file = "$class.pm") =~ s{::}{/}g;
   my $inc_entry = $INC{$file} or return;
   (my $path = $inc_entry) =~ s{ $file \z }{}mx;

   $path ||= io->cwd if !defined $path || !length $path;

   my $home = io($path)->absolute;

   $home = $home->parent while $home =~ m{ b?lib \z }mx;

   return $home if $home =~ m{ xt \z }mx;

   return $home if grep { $home->catfile($_)->exists } dist_indicator_file_list;

   ($path = $inc_entry) =~ s{ \.pm \z }{}mx;
   $home = io($path)->absolute;

   return $home if $home->exists;

   return;
}

around 'BUILDARGS' => sub {
   my ($orig, $self, @args) = @_;

   my $attr   = $orig->($self, @args);
   my $schema = File::DataClass::Schema->new( storage_class => 'Any' );

   if ($attr->{appclass}) {
      my $home = io $attr->{home} if defined $attr->{home} and -d $attr->{home};
      my $env_var = $ENV{ uc $attr->{appclass} . '_home' };

      $home = io $env_var     if !$home and $env_var and -d $env_var;
      $home = find_home $attr if !$home;
      $attr->{home} = $home   if  $home;
   }

   if ($attr->{appclass} && $attr->{home}) {
      my ($config_home, $config_file) = find_config $attr;

      $attr->{config_home} = $config_home if $config_home;
      $attr->{config_file} = $config_file if $config_file;
   }

   if ($attr->{config_file}) {
      $attr = { %{$attr}, %{$schema->load($attr->{config_file})} };
   }

   if (my $file = $attr->{local_config_file}) {
      my $config_file = $attr->{config_home}->catfile($file);

      if ($config_file->exists) {
         $attr->{local_config_file} = $config_file;
         $attr = { %{$attr}, %{$schema->load($config_file)} };
      }
   }

   if ($attr->{home} && $attr->{home}->catdir('var')->exists) {
      $attr->{vardir} = $attr->{home}->catdir('var');
   }

   return $attr;
};

use namespace::autoclean;

1;
