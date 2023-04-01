package MCat::Form::ChangePassword;

use HTML::Forms::Constants qw( FALSE META TRUE );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Model::DBIC';
with    'HTML::Forms::Role::Defaults';

has '+title'               => default => 'Change Password';
has '+default_wrapper_tag' => default => 'fieldset';
has '+do_form_wrapper'     => default => TRUE;
has '+info_message'        => default => 'User change password';

has_field 'password' => type => 'Password';

has_field '_password' => type => 'PasswordConf', label => 'and again',
   password_field => 'password';

has_field 'submit' => type => 'Submit';

use namespace::autoclean -except => META;

1;
