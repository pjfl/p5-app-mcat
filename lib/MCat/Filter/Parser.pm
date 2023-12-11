package MCat::Filter::Parser;

use HTML::Forms::Constants     qw( EXCEPTION_CLASS FALSE TRUE );
use HTML::Forms::Types         qw( HashRef );
use File::DataClass::Functions qw( ensure_class_loaded );
use JSON::MaybeXS              qw( decode_json );
use Ref::Util                  qw( is_hashref is_scalarref );
use Unexpected::Functions      qw( throw Unspecified );
use MCat::Filter;
use Try::Tiny;
use Moo;

has 'config' => is => 'ro', isa => HashRef, default => sub { {} };

sub parse {
   my ($self, $json) = @_;

   throw Unspecified, ['json'] unless defined $json && is_scalarref $json;

   my $data;

   try { $data = decode_json($json) }
   catch { throw $_ };

   my $filter = MCat::Filter->new;
   my $node   = $self->_build_node($data);

   $filter->add_node($node);

   throw 'Filter [_1] contains empty nodes', [$filter]
      if $filter->contains_empty_nodes;

   return $filter;
}

# Private methods
sub _build_node {
   my ($self, $data) = @_;

   throw 'Hash reference required' unless is_hashref $data;

   my $type = delete $data->{type} or throw 'Type attribute missing';

   $type =~ s{\.}{::}gmx;

   my $nodes = delete $data->{nodes} || [];
   my $class = "MCat::Filter::${type}";

   $class = "MCat::Filter::Node::${type}" if $type =~ m{ \A (Rule|Logic) }mx;

   ensure_class_loaded $class;

   for my $key (keys %{$data}) {
      my $value = $data->{$key} or next;

      if (is_hashref $value) { $data->{$key} = $self->_build_node($value) }
      elsif ($value eq 'true') {
         $data->{$key} = TRUE unless $type eq 'Type::String';
      }
      elsif ($value eq 'false') {
         $data->{$key} = FALSE unless $type eq 'Type::String';
      }
   }

   my $node;

   try { $node = $class->new(%{$data}, %{$self->config}) }
   catch { throw $_ };

   for my $child (@{$nodes}) {
      $node->add_node($self->_build_node($child));
   }

   return $node;
}

use namespace::autoclean;

1;
