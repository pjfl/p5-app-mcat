package MCat::Form::ChangePassword;

use HTML::Forms::Constants qw( FALSE META TRUE );
use Try::Tiny;
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Model::DBIC';
with    'HTML::Forms::Role::Defaults';

has '+title'               => default => 'Change Password';
has '+default_wrapper_tag' => default => 'fieldset';
has '+do_form_wrapper'     => default => TRUE;
has '+info_message'        => default => 'User change password';

has 'log' => is => 'ro', predicate => 'has_log';

has_field 'old_password' => type => 'Password', label => 'Old Password';

has_field 'password' => type => 'Password', label => 'New Password';

has_field '_password' => type => 'PasswordConf', label => 'and again',
   password_field => 'password';

has_field 'submit' => type => 'Submit';

sub validate {
   my $self   = shift;
   my $passwd = $self->field('old_password');

   try   { $self->item->authenticate($passwd->value) }
   catch {
      $passwd->add_error($_->original);
      $self->log->alert($_, $self->context) if $self->has_log;
   };

   return;
}

use namespace::autoclean -except => META;

1;
