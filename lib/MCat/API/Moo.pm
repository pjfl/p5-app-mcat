package MCat::API::Moo;

use mro;
use strictures;

use MCat::Constants       qw( EXCEPTION_CLASS FALSE API_META TRUE );
use Ref::Util             qw( is_arrayref );
use Sub::Install          qw( install_sub );
use Unexpected::Functions qw( throw );
use MCat::API::Meta;

my @banished_keywords = ( API_META );

my @block_attributes  = qw();
my @page_attributes   = qw();

sub import {
   my ($class, @args) = @_;

   my $target = caller;
   my @target_isa = @{ mro::get_linear_isa($target) };
   my $method = API_META;
   my $meta;

   if (@target_isa) {
      # Don't add this to a role. The ISA of a role is always empty!
      if ($target->can($method)) { $meta = $target->$method }
      else {
         $meta = MCat::API::Meta->new({ target => $target, @args });

         install_sub { as => $method, into => $target, code => sub {
            return $meta;
         }, };
      }
   }
   else {
      throw 'No meta object' unless $target->can($method);

      $meta = $target->$method;
   }

   my $rt_info_key = 'non_methods';
   my $info = $Role::Tiny::INFO{ $target };

   my $has_column = sub {
      my ($arg, %attributes) = @_;

      my $names = is_arrayref $arg ? $arg : [$arg];

      for my $name (@{$names}) {
         _assert_no_banished_keywords($target, $name);
         $meta->add_to_column_list({ name => $name, %attributes });
      }

      return;
   };

   $info->{$rt_info_key}{has_api_column} = $has_column if $info;

   install_sub { as => 'has_api_column', into => $target, code => $has_column };

   my $has_method = sub {
      my ($arg, %attributes) = @_;

      my $names = is_arrayref $arg ? $arg : [$arg];

      for my $name (@{$names}) {
         _assert_no_banished_keywords($target, $name);
         $meta->add_to_method_list({ name => $name, %attributes });
      }

      return;
   };

   $info->{$rt_info_key}{has_api_method} = $has_method if $info;

   install_sub { as => 'has_api_method', into => $target, code => $has_method };

   return;
}

# Private functions
sub _assert_no_banished_keywords {
   my ($target, $name) = @_;

   for my $ban (grep { $_ eq $name } @banished_keywords) {
      throw 'Method [_1] used by class [_2] as an attribute', [$ban, $target];
   }

   return;
}

use namespace::autoclean;

1;
