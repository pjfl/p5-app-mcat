package MCat::Form::Profile;

use HTML::Forms::Constants qw( FALSE META NUL TRUE );
use HTML::Forms::Types     qw( HashRef Object );
use Type::Utils            qw( class_type );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms';
with    'HTML::Forms::Role::Defaults';

has '+title'                  => default => 'User Profile';
has '+info_message'           => default => 'Update profile information';
has '+use_init_obj_over_item' => default => TRUE;

has '+init_object' => default => sub {
   my $self    = shift;
   my $user    = $self->user;
   my $profile = $user->profile;
   my $value   = $profile ? $profile->value : {};

   $value->{name} = $user->name;
   $value->{email} = $user->email;
   return $value;
};

has 'user' =>
   is       => 'ro',
   isa      => class_type('MCat::Schema::Result::User'),
   required => TRUE;

has_field 'name' =>
   type          => 'Display',
   element_class => 'tile',
   label         => 'User Name';

has_field 'email' =>
   type          => 'Display',
   element_class => 'tile',
   label         => 'Email Address';

has_field 'timezone' => type => 'Timezone';

has_field 'enable_2fa' =>
   type   => 'Boolean',
   info   =>
      'Additional security questions should be answered if 2FA is enabled',
   label  => 'Enable 2FA',
   toggle => { -checked => ['mobile_phone', 'postcode'] };

has_field 'mobile_phone' =>
   type  => 'PosInteger',
   label => 'Mobile #',
   size  => 12,
   title => 'Additional security question used by 2FA token reset';

has_field 'postcode' =>
   size  => 8,
   title => 'Additional security question used by 2FA token reset';

has_field 'skin' =>
   type    => 'Select',
   options => [
      { label => 'Classic', value => 'classic' },
      { label => 'None',    value => 'none' },
   ];

sub default_skin {
   return shift->context->config->skin;
}

has_field 'menu_location' =>
   type    => 'Select',
   default => 'header',
   label   => 'Menu Location',
   options => [
      { label => 'Header',  value => 'header' },
      { label => 'Sidebar', value => 'sidebar' },
   ];

has_field 'link_display' =>
   type    => 'Select',
   default => 'both',
   label   => 'Link Display',
   options => [
      { label => 'Both', value => 'both' },
      { label => 'Icon', value => 'icon' },
      { label => 'Text', value => 'text' },
   ];

has_field 'theme' =>
   type    => 'Select',
   default => 'theme-light',
   label   => 'Colour Scheme',
   options => [
      { label => 'Dark',   value => 'dark-theme' },
      { label => 'Light',  value => 'light-theme' },
      { label => 'System', value => 'system-theme' },
   ];

has_field 'base_colour' =>
   type    => 'Colour',
   label   => 'Base Colour',
   options => [];

has_field 'view' =>
   type          => 'Link',
   label         => 'View',
   element_class => ['form-button pageload'],
   wrapper_class => ['input-button', 'inline'];

has_field 'submit' => type => 'Button';

after 'after_build_fields' => sub {
   my $self    = shift;
   my $context = $self->context;

   unless ($self->user->enable_2fa) {
      $self->field('enable_2fa')->hide_info(TRUE);
      $self->field('mobile_phone')->add_wrapper_class('hide');
      $self->field('postcode')->add_wrapper_class('hide');
   }

   my $field  = $self->field('base_colour');
   my $colour = $context->config->default_base_colour;

   $field->default($colour);
   push @{$field->options}, { value => $colour };

   my $view = $context->uri_for_action('user/view', [$self->user->id]);

   $self->field('view')->href($view->as_string);
   $self->field('submit')->add_wrapper_class(['inline', 'right']);

   return;
};

sub validate {
   my $self       = shift;
   my $enable_2fa = $self->field('enable_2fa')->value ? TRUE : FALSE;
   my $user       = $self->user;
   my $value      = $user->profile_value;

   $value->{base_colour}   = $self->field('base_colour')->value;
   $value->{enable_2fa}    = $enable_2fa ? \1 : \0;
   $value->{link_display}  = $self->field('link_display')->value;
   $value->{menu_location} = $self->field('menu_location')->value;
   $value->{mobile_phone}  = $self->field('mobile_phone')->value;
   $value->{postcode}      = $self->field('postcode')->value;
   $value->{skin}          = $self->field('skin')->value;
   $value->{theme}         = $self->field('theme')->value;
   $value->{timezone}      = $self->field('timezone')->value;

   $self->context->model('Preference')->update_or_create({
      name => 'profile', user_id => $user->id, value => $value
   }, {
      key  => 'preference_user_id_name_uniq'
   });

   $user->set_totp_secret($enable_2fa);

   my $session = $self->context->session;

   if ($session->id == $user->id) {
      $session->base_colour($value->{base_colour});
      $session->enable_2fa($enable_2fa);
      $session->link_display($value->{link_display});
      $session->menu_location($value->{menu_location});
      $session->skin($value->{skin});
      $session->theme($value->{theme});
      $session->timezone($value->{timezone});
   }

   return;
}

use namespace::autoclean -except => META;

1;
