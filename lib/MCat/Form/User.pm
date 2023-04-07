package MCat::Form::User;

use HTML::Forms::Constants qw( FALSE META TRUE );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Model::DBIC';
with    'HTML::Forms::Role::Defaults';

has '+title'               => default => 'User';
has '+default_wrapper_tag' => default => 'fieldset';
has '+do_form_wrapper'     => default => TRUE;
has '+info_message'        => default => 'Create or edit users';
has '+item_class'          => default => 'User';

has_field 'name', required => 1;

has_field 'active' => type => 'Boolean', default => TRUE;

has_field 'password' => type => 'Password';

has_field 'password_expired' => type => 'Boolean', default => FALSE;

has_field 'role' => type => 'Select';

has_field 'timezone' => type => 'Timezone';

has_field 'submit' => type => 'Submit';

use namespace::autoclean -except => META;

1;
