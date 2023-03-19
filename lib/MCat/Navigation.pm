use utf8; # -*- coding: utf-8; -*-
package MCat::Navigation;

use HTML::StateTable::Constants qw( FALSE TRUE );
use HTML::StateTable::Types     qw( ArrayRef HashRef Str );
use Type::Utils                 qw( class_type );
use HTML::Tiny;
use JSON::MaybeXS;
use Try::Tiny;
use Moo;

has 'container_tag' => is => 'ro', isa => Str, default => 'div';

has 'context' => is => 'ro', isa => class_type('MCat::Context'),
   required => TRUE;

has 'label' => is => 'ro', isa => Str, default => '≡';

has 'model' => is => 'ro', isa => class_type('MCat::Model'), required => TRUE;

has 'section_title' => is => 'ro', isa => Str, default => 'Global';

has 'sections' => is => 'ro', isa => ArrayRef, default => sub { [] };

has '_container' => is => 'lazy', isa => Str, default => sub {
   my $self = shift;
   my $tag  = $self->container_tag;

   return $self->_html->$tag($self->_data);
};

has '_data' => is => 'lazy', isa => HashRef, default => sub {
   my $self = shift;

   return {
      'class' => 'state-navigation',
         'data-navigation-config' => $self->_json->encode({
         'label'      => $self->label,
         'menus'      => { map { $_ => $self->_lists->{$_} } @{$self->_order} },
         'moniker'    => $self->model->moniker,
         'properties' => { title => 'Navigation' },
      }),
   };
};

has '_html' =>
   is      => 'ro',
   isa     => class_type('HTML::Tiny'),
   default => sub { HTML::Tiny->new };

has '_json' => is => 'ro', isa => class_type(JSON::MaybeXS::JSON),
   default => sub {
      return JSON::MaybeXS->new( convert_blessed => TRUE, utf8 => FALSE );
   };

has '_lists' => is => 'ro', isa => HashRef, default => sub { {} };

has '_name' => is => 'rw', isa => Str, default => '';

has '_order' => is => 'ro', isa => ArrayRef, default => sub { [] };

around 'BUILDARGS' => sub {
   my ($orig, $self, @args) = @_;

   my $attr   = $orig->($self, @args);
   my $config = $attr->{context}->config->navigation;

   return { %{$attr}, %{$config} };
};

sub item {
   my ($self, $label, @args) = @_;

   push @{$self->_lists->{$self->_name}->[1]}, [$label => $self->_uri(@args)];
   return $self;
}

sub list {
   my ($self, $name, $title) = @_;

   $self->_name($name);
   $self->_lists->{$name} = [ $title, [] ];
   push @{$self->_order}, $name;
   return $self;
}

sub render {
   my $self = shift;
   my $output;

   $self->_add_sections;

   try   { $output = $self->_container }
   catch { $output = $_ };

   return $output;
}

sub section {
   my ($self, @args) = @_;

   push @{$self->sections}, [@args];
   return $self;
}

# Private methods
sub _add_sections {
   my $self = shift;
   my $list = $self->list('_sections', $self->section_title);

   for my $section (@{$self->sections}) { $self->item(@{$section}) }

   return;
}

sub _uri {
   my ($self, @args) = @_;

   return $self->context->uri_for_action(@args);
}

use namespace::autoclean;

1;
