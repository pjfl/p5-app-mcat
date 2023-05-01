use utf8; # -*- coding: utf-8; -*-
package MCat::Navigation;

use HTML::StateTable::Constants  qw( EXCEPTION_CLASS FALSE NUL TRUE );
use HTML::StateTable::Types      qw( ArrayRef HashRef Str URI );
use HTTP::Status                 qw( HTTP_OK );
use MCat::Util                   qw( clear_redirect formpost
                                     maybe_render_partial );
use Ref::Util                    qw( is_hashref );
use Scalar::Util                 qw( blessed );
use Type::Utils                  qw( class_type );
use Unexpected::Functions        qw( throw NoMethod UnknownModel );
use MCat::Navigation::Attributes qw();
use HTML::Tiny;
use JSON::MaybeXS;
use Try::Tiny;
use Moo;

has 'confirm_message' => is => 'ro', isa => Str, default => 'Are you sure ?';

has 'container_name' => is => 'ro', isa => Str, default => 'standard-content';

has 'container_tag' => is => 'ro', isa => Str, default => 'div';

has 'content_name' => is => 'ro', isa => Str, default => 'panel-content';

has 'context' => is => 'ro', isa => class_type('MCat::Context'),
   required => TRUE, weak_ref => TRUE;

has 'global' => is => 'ro', isa => ArrayRef, default => sub { [] };

has 'global_location' => is => 'ro', isa => Str, default => 'header';

has 'label' => is => 'lazy', isa => Str, init_arg => undef, default => sub {
   my $self = shift;

   return $self->context->request->uri_for($self->_label)->as_string
      if $self->_label =~ m{ / }mx;

   return $self->_label;
};

has '_label' => is => 'ro', isa => Str, init_arg => 'label', default => '≡';

has 'logo' => is => 'lazy', isa => Str, init_arg => undef, default => sub {
   my $self = shift;

   return $self->context->request->uri_for($self->_logo)->as_string
      if $self->_logo =~ m{ / }mx;

   return NUL;
};

has '_logo' => is => 'ro', isa => Str, init_arg => 'logo', default => NUL;

has 'messages' => is => 'ro', isa => HashRef, default => sub { {} };

has 'model' => is => 'ro', isa => class_type('MCat::Model'), required => TRUE;

has 'title' => is => 'ro', isa => Str, default => 'Navigation';

has 'title_abbrev' => is => 'ro', isa => Str, default => 'Nav';

has 'title_entry' => is => 'lazy', isa => Str, default => sub {
   my $self  = shift;
   my @parts = split m{ / }mx, $self->context->action;

   return $self->_get_menu_label($parts[0] . '/' . $parts[-1]);
};

has '_base_url' => is => 'lazy', isa => URI, default => sub {
   return shift->context->request->uri_for(NUL);
};

has '_container' => is => 'lazy', isa => Str, default => sub {
   my $self = shift;
   my $tag  = $self->container_tag;

   return $self->_html->$tag($self->_data);
};

has '_data' => is => 'lazy', isa => HashRef, default => sub {
   my $self  = shift;
   my $class = 'state-navigation navigation-' . $self->global_location;

   return {
      'class' => $class,
      'data-navigation-config' => $self->_json->encode({
         'menus'      => $self->_menus,
         'messages'   => $self->_messages,
         'moniker'    => $self->model->moniker,
         'properties' => {
            'base-url'       => $self->_base_url,
            'confirm'        => $self->confirm_message,
            'container-name' => $self->container_name,
            'content-name'   => $self->content_name,
            'label'          => $self->label,
            'location'       => $self->global_location,
            'logo'           => $self->logo,
            'skin'           => $self->context->session->skin,
            'title'          => $self->title,
            'title-abbrev'   => $self->title_abbrev,
            'verify-token'   => $self->context->verification_token,
            'version'        => MCat->VERSION,
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

has '_menus' => is => 'lazy', isa => HashRef, default => sub {
   my $self = shift;

   return { map { $_ => $self->_lists->{$_} } @{$self->_order} };
};

has '_messages' => is => 'lazy', isa => HashRef, default => sub {
   my $self    = shift;
   my $context = $self->context;

   return {
      %{$self->messages},
      'messages-url' => $context->uri_for_action('api/navigation_messages')
   };
};

has '_name' => is => 'rwp', isa => Str, default => NUL;

has '_order' => is => 'ro', isa => ArrayRef, default => sub { [] };

around 'BUILDARGS' => sub {
   my ($orig, $self, @args) = @_;

   my $attr   = $orig->($self, @args);
   my $config = $attr->{context}->config;

   return { %{$attr}, %{$config->navigation} };
};

sub BUILD {
   my $self = shift;

   maybe_render_partial $self->context;

   return;
}

sub crud {
   my ($self, $moniker, $existing_id, $create_id) = @_;

   $self->item("${moniker}/create", [$create_id]) if $create_id;
   $self->item(formpost, "${moniker}/delete", [$existing_id]);
   $self->item("${moniker}/edit", [$existing_id]);
   $self->item("${moniker}/view", [$existing_id]);
   return $self;
}

sub finalise {
   my $self    = shift;
   my $context = $self->context;
   my $request = $context->request;

   return unless $self->is_script_request
      && $request->query_parameters->{navigation};

   $self->_add_global;

   my $body = $self->_json->encode({
      'menus'        => $self->_menus,
      'title-entry'  => $self->title_entry,
      'verify-token' => $context->verification_token,
   });

   $context->stash(
      code => HTTP_OK, finalised => TRUE, body => $body, view => 'json'
   );
   return;
}

sub is_script_request {
   my $self   = shift;
   my $header = $self->context->request->header('x-requested-with') // NUL;

   return lc $header eq 'xmlhttprequest' ? TRUE : FALSE;
}

sub item {
   my ($self, @args) = @_;

   my $label;

   if (is_hashref $args[0]) {
      $label = shift @args;
      $label->{name} = $self->_get_menu_label($args[0]);
   }
   else { $label = $self->_get_menu_label($args[0]) }

   my ($moniker, $method) = split m{ / }mx, $args[0];

   if ($self->model->allowed($self->context, $moniker, $method)) {
      my $list = $self->_lists->{$self->_name}->[1];

      push @{$list}, [$label => $self->_uri(@args)];
   }
   else { clear_redirect $self->context }

   return $self;
}

sub list {
   my ($self, $name, $title) = @_;

   $self->_set__name($name);
   $self->_lists->{$name} = [ $title // NUL, [] ];
   push @{$self->_order}, $name;
   return $self;
}

sub menu {
   my ($self, $name) = @_;

   my $lists = $self->_lists;

   push @{$lists->{$self->_name}->[1]}, $name if exists $lists->{$name};
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

# Private methods
sub _add_global {
   my $self = shift;
   my $list = $self->list('_global');

   for my $action (@{$self->global}) {
      my ($moniker, $method) = split m{ / }mx, $action;

      if ($self->model->allowed($self->context, $moniker, $method)) {
         if ($method eq 'menu') {
            $self->context->models->{$moniker}->menu($self->context);
            $self->_set__name('_global');
         }

         push @{$self->_lists->{$self->_name}->[1]}, $moniker
            if exists $self->_lists->{$moniker};

         $list->item($action);
      }
      else { clear_redirect $self->context }
   }

   return;
}

sub _get_attributes {
   my ($self, $action) = @_;

   my ($moniker, $method) = split m{ / }mx, $action;
   my $model = $self->context->models->{$moniker}
      or throw UnknownModel, [$moniker];
   my $code_ref = $model->can($method)
      or throw NoMethod, [ blessed $model, $method ];

   return MCat::Navigation::Attributes->fetch($code_ref) // {};
}

sub _get_menu_label {
   my ($self, $action) = @_;

   my $menu = $self->_get_attributes($action)->{Nav};

   return $menu ? $menu->[0] : NUL;
}

sub _uri {
   my ($self, @args) = @_;

   my $action = $args[0];

   return NUL if $action =~ m{ /menu \z }mx;

   return $self->context->uri_for_action(@args);
}

1;
