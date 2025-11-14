package MCat::Constants;

use strictures;
use parent 'Exporter::Tiny';

use Class::Usul::Cmd::Constants qw();

our @EXPORT = qw( BUG_STATE_ENUM SQL_FALSE SQL_NOW SQL_TRUE );

sub import {
   my $class       = shift;
   my $global_opts = { $_[0] && ref $_[0] eq 'HASH' ? %{+ shift } : () };
   my @wanted      = @_;
   my $usul_const  = {}; $usul_const->{$_} = 1 for (@wanted);
   my @self        = ();

   for (@EXPORT) { push @self, $_ if delete $usul_const->{$_} }

   $global_opts->{into} ||= caller;
   Class::Usul::Cmd::Constants->import($global_opts, keys %{$usul_const});
   $class->SUPER::import($global_opts, @self);
   return;
}

sub BUG_STATE_ENUM () { [ qw( assigned fixed open wontfix ) ] }
sub SQL_FALSE      () { \q{false} }
sub SQL_NOW        () { \q{NOW()} }
sub SQL_TRUE       () { \q{true} }

1;
