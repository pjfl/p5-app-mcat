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
has '+info_message'           => default => 'Update your information';
has '+use_init_obj_over_item' => default => TRUE;

has '+init_object' => default => sub {
   my $self    = shift;
   my $profile = $self->user->profile;

   return $profile ? $profile->value : {};
};

has 'user' => is => 'ro', isa => class_type('MCat::Schema::Result::User'),
   required => TRUE;

has_field 'timezone' => type => 'Timezone';

has_field 'submit' => type => 'Submit';

sub validate {
   my $self  = shift;
   my $rs    = $self->context->model('Preference');
   my $value = { timezone => $self->field('timezone')->value };

   $rs->update_or_create({
      name => 'profile', user_id => $self->user->id, value => $value
   }, { key => 'preference_name' });
   $self->context->session->timezone($value->{timezone});

   return;
}

use namespace::autoclean -except => META;

1;
