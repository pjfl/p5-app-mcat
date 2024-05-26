package MCat::Navigation;

use utf8; # -*- coding: utf-8; -*-

use HTML::StateTable::Constants qw( FALSE NUL SPC TRUE );
use HTTP::Status                qw( HTTP_OK );
use HTML::StateTable::Types     qw( ArrayRef Bool HashRef PositiveInt
                                    Str URI );
use MCat::Util                  qw( clear_redirect formpost );
use Ref::Util                   qw( is_hashref );
use Scalar::Util                qw( blessed );
use Type::Utils                 qw( class_type );
use HTML::Tiny;
use JSON::MaybeXS;
use Try::Tiny;
use Moo;

has 'confirm_message' => is => 'ro', isa => Str, default => 'Are you sure ?';

has 'container_class' => is => 'lazy', isa => Str, default => sub {
   my $self = shift;

   return $self->container_name . SPC . $self->container_layout;
};

has 'container_layout' => is => 'rw', isa => Str, default => 'centred';

has 'container_name' => is => 'ro', isa => Str, default => 'standard';

has 'container_tag' => is => 'ro', isa => Str, default => 'div';

has 'content_name' => is => 'ro', isa => Str, default => 'panel';

has 'context' =>
   is       => 'ro',
   isa      => class_type('MCat::Context'),
   required => TRUE,
   weak_ref => TRUE;

has 'control_label' => is => 'lazy', isa => Str, init_arg => undef,
   default => sub {
      my $self = shift;

      return $self->context->request->uri_for($self->_control_label)->as_string
         if $self->_control_label =~ m{ / }mx;

      return $self->_control_label;
   };

has '_control_label' => is => 'ro', isa => Str, init_arg => 'control_label',
   default => '≡';

has 'global' => is => 'ro', isa => ArrayRef, default => sub { [] };

has 'link_display' => is => 'lazy', isa => Str, init_arg => undef,
   default => sub {
      my $self = shift;
      my $session = $self->context->session;

      return $session->link_display || $self->_link_display;
   };

has '_link_display' => is => 'ro', isa => Str, init_arg => 'link_display',
   default => 'both';

has 'logo' => is => 'lazy', isa => Str, init_arg => undef, default => sub {
   my $self = shift;

   return $self->context->request->uri_for($self->_logo)->as_string
      if $self->_logo =~ m{ / }mx;

   return NUL;
};

has '_logo' => is => 'ro', isa => Str, init_arg => 'logo', default => NUL;

has 'media_break' => is => 'ro', isa => PositiveInt, default => 680;

has 'menu_location' => is => 'lazy', isa => Str, default => sub {
   my $self    = shift;
   my $session = $self->context->session;

   return $session->menu_location || $self->_menu_location;
};

has '_menu_location' => is => 'ro', isa => Str, init_arg => 'menu_location',
   default => 'header';

has 'messages' => is => 'ro', isa => HashRef, default => sub { {} };

has 'model' => is => 'ro', isa => class_type('MCat::Model'), required => TRUE;

has 'title' => is => 'ro', isa => Str, default => 'Navigation';

has 'title_abbrev' => is => 'ro', isa => Str, default => 'Nav';

has 'title_entry' => is => 'lazy', isa => Str, default => sub {
   my $self  = shift;
   my @parts = split m{ / }mx, $self->context->action;
   my $label = $self->_get_nav_label($parts[0] . '/' . $parts[-1]);

   return (split m{ \| }mx, $label)[0] // NUL;
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
   my $self     = shift;
   my $location = 'navigation-'  . $self->menu_location;
   my $display  = 'link-display-' . $self->link_display;

   return {
      'id'    => 'navigation',
      'class' => "navigation ${location} ${display}",
      'data-navigation-config' => $self->_json->encode({
         'menus'      => $self->_menus,
         'messages'   => $self->_messages,
         'moniker'    => $self->model->moniker,
         'properties' => {
            'base-url'         => $self->_base_url,
            'confirm'          => $self->confirm_message,
            'container-layout' => $self->container_layout,
            'container-name'   => $self->container_name,
            'content-name'     => $self->content_name,
            'control-label'    => $self->control_label,
            'link-display'     => $self->link_display,
            'location'         => $self->menu_location,
            'logo'             => $self->logo,
            'media-break'      => $self->media_break,
            'skin'             => $self->context->session->skin,
            'title'            => $self->title,
            'title-abbrev'     => $self->title_abbrev,
            'verify-token'     => $self->context->verification_token,
            'version'          => MCat->VERSION,
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
      'container-layout' => $self->container_layout,
      'menus'            => $self->_menus,
      'title-entry'      => $self->title_entry,
      'verify-token'     => $context->verification_token,
   });

   $context->stash(
      code => HTTP_OK, finalised => TRUE, body => $body, view => 'json'
   );
   return;
}

sub finalise_script_request {
   my $self = shift;

   $self->context->stash(code => HTTP_OK) if $self->is_script_request;

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
      $label->{name} = $self->_get_nav_label($args[0]);
   }
   else { $label = $self->_get_nav_label($args[0]) }

   if ($self->model->is_authorised($self->context, $args[0])) {
      my $list = $self->_lists->{$self->_name}->[1];
      my ($text, $icon);

      if (is_hashref $label) {
         ($text, $icon) = split m{ \| }mx, $label->{name};
         $label->{name} = $text;
         $text = $label;
      }
      else { ($text, $icon) = split m{ \| }mx, $label }

      $icon = $self->context->request->uri_for($icon)
         if $icon && $icon =~ m{ / }mx;

      push @{$list}, [$text => $self->_uri(@args), $icon];
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

      if ($self->model->is_authorised($self->context, $action)) {
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

sub _get_nav_label {
   my ($self, $action) = @_;

   my $attr = try { $self->context->get_attributes($action) };

   return $attr->{Nav}->[0] if $attr && defined $attr->{Nav};

   return NUL;
}

sub _uri {
   my ($self, @args) = @_;

   my $action = $args[0];

   return NUL if $action =~ m{ /menu \z }mx;

   return $self->context->uri_for_action(@args);
}

1;
