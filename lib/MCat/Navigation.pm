use utf8; # -*- coding: utf-8; -*-
package MCat::Navigation;

use attributes ();

use HTML::StateTable::Constants qw( EXCEPTION_CLASS FALSE NUL TRUE );
use HTML::StateTable::Types     qw( ArrayRef HashRef Str );
use MCat::Util                  qw( formpost );
use Ref::Util                   qw( is_hashref );
use Scalar::Util                qw( blessed );
use Type::Utils                 qw( class_type );
use HTML::Tiny;
use JSON::MaybeXS;
use Try::Tiny;
use Unexpected::Functions       qw( throw );
use Moo;

has 'confirm_message' => is => 'ro', isa => Str, default => 'Are you sure ?';

has 'container_tag' => is => 'ro', isa => Str, default => 'div';

has 'context' => is => 'ro', isa => class_type('MCat::Context'),
   required => TRUE;

has '_global' => is => 'ro', isa => ArrayRef, init_arg => 'global',
   default => sub { [] };

has 'global_title' => is => 'ro', isa => Str, default => 'Global';

has 'label' => is => 'ro', isa => Str, default => '≡';

has 'model' => is => 'ro', isa => class_type('MCat::Model'), required => TRUE;

has 'title' => is => 'ro', isa => Str, default => 'Navigation';

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
         'menus'      => { map { $_ => $self->_lists->{$_} } @{$self->_order} },
         'moniker'    => $self->model->moniker,
         'properties' => {
            'confirm'      => $self->confirm_message,
            'label'        => $self->label,
            'title'        => $self->title,
            'verify-token' => $self->context->verification_token,
         },
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

has '_name' => is => 'rwp', isa => Str, default => NUL;

has '_order' => is => 'ro', isa => ArrayRef, default => sub { [] };

around 'BUILDARGS' => sub {
   my ($orig, $self, @args) = @_;

   my $attr   = $orig->($self, @args);
   my $config = $attr->{context}->config->navigation;

   return { %{$attr}, %{$config} };
};

sub crud {
   my ($self, $moniker, $existing_id, $create_id) = @_;

   $self->item("${moniker}/create", [$create_id]) if $create_id;
   $self->item(formpost, "${moniker}/delete", [$existing_id]);
   $self->item("${moniker}/edit", [$existing_id]);
   $self->item("${moniker}/view", [$existing_id]);
   return $self;
}

sub item {
   my ($self, @args) = @_;

   my $label;

   if (is_hashref $args[0]) {
      $label = shift @args;
      $label->{name} = $self->_get_menu_label($args[0]);
   }
   else { $label = $self->_get_menu_label($args[0]) }

   push @{$self->_lists->{$self->_name}->[1]}, [$label => $self->_uri(@args)];
   return $self;
}

sub list {
   my ($self, $name, $title) = @_;

   $self->_set__name($name);
   $self->_lists->{$name} = [ $title, [] ];
   push @{$self->_order}, $name;
   return $self;
}

sub render {
   my $self = shift;
   my $output;

   $self->_add_global;

   try   { $output = $self->_container }
   catch { $output = $_ };

   return $output;
}

sub global {
   my ($self, @args) = @_;

   push @{$self->_global}, [@args];
   return $self;
}

# Private methods
sub _add_global {
   my $self = shift;
   my $list = $self->list('_global', $self->global_title);

   for my $actionp (@{$self->_global}) {
      $list->item($actionp);

      my ($moniker, $method) = split m{ / }mx, $actionp;

      push @{$self->_lists->{$self->_name}->[1]}, $moniker
         if exists $self->_lists->{$moniker};
   }

   return;
}

sub _get_attributes {
   my ($self, $actionp) = @_;

   my ($moniker, $method) = split m{ / }mx, $actionp;
   my $model = $self->context->models->{$moniker}
      or throw 'Moniker [_1] not found in models', [$moniker];
   my $code_ref = $model->can($method)
      or throw 'Class [_1] has no method [_2]', [ blessed $model, $method ];

   return attributes::get($code_ref) // {};
}

sub _get_menu_label {
   my ($self, $actionp) = @_;

   my $menu = $self->_get_attributes($actionp)->{Menu};

   return $menu ? $menu->[0] : NUL;
}

sub _uri {
   my ($self, @args) = @_;

   return $self->context->uri_for_action(@args);
}

use namespace::autoclean;

1;
