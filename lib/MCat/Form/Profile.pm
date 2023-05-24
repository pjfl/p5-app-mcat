package MCat::Form::Profile;

use HTML::Forms::Constants qw( FALSE META TRUE );
use HTML::Forms::Types     qw( HashRef Object );
use Type::Utils            qw( class_type );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms';
with    'HTML::Forms::Role::Defaults';

has '+title'                  => default => 'Profile';
has '+default_wrapper_tag'    => default => 'fieldset';
has '+do_form_wrapper'        => default => TRUE;
has '+info_message'           => default => 'Update profile information';
has '+use_init_obj_over_item' => default => TRUE;

has '+init_object' => default => sub {
   my $self    = shift;
   my $profile = $self->user->profile;
   my $value   = $profile ? $profile->value : {};

   $value->{name} = $self->user->name;
   return $value;
};

has 'user' => is => 'ro', isa => class_type('MCat::Schema::Result::User'),
   required => TRUE;

has_field 'name' => type => 'Display', label => 'User Name';

has_field 'email' => type => 'Email';

has_field 'enable_2fa' => type => 'Boolean';

has_field 'mobile_phone' => type => 'PosInteger', label => 'Mobile #',
   size => 12;

has_field 'postcode', size => 8;

has_field 'skin' => type => 'Select', default => 'classic', options => [
   { label => 'Classic', value => 'classic' },
   { label => 'Funky',   value => 'funky' },
];

has_field 'timezone' => type => 'Timezone';

has_field 'submit' => type => 'Submit';

sub validate {
   my $self       = shift;
   my $enable_2fa = $self->field('enable_2fa')->value ? TRUE : FALSE;
   my $value      = $self->user->profile_value;

   $value->{email}        = $self->field('email')->value;
   $value->{enable_2fa}   = $enable_2fa ? \1 : \0;
   $value->{mobile_phone} = $self->field('mobile_phone')->value;
   $value->{postcode}     = $self->field('postcode')->value;
   $value->{skin}         = $self->field('skin')->value;
   $value->{timezone}     = $self->field('timezone')->value;

   $self->context->model('Preference')->update_or_create({
      name => 'profile', user_id => $self->user->id, value => $value
   }, {
      key  => 'preference_user_id_name_uniq'
   });

   my $session = $self->context->session;

   $self->user->set_totp_secret($enable_2fa);
   $session->enable_2fa($enable_2fa);
   $session->skin($value->{skin});
   $session->timezone($value->{timezone});
   return;
}

use namespace::autoclean -except => META;

1;
