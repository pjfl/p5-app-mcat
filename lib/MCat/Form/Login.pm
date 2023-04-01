package MCat::Form::Login;

use HTML::Forms::Constants qw( FALSE META TRUE );
use Try::Tiny;
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms';
with    'HTML::Forms::Role::Defaults';

has '+title'               => default => 'Login';
has '+default_wrapper_tag' => default => 'fieldset';
has '+do_form_wrapper'     => default => TRUE;
has '+info_message'        => default => '';
has '+item_class'          => default => 'User';

has 'log' => is => 'ro', predicate => 'has_log';

has_field 'name', required => TRUE;

has_field 'password', type => 'Password', required => TRUE;

has_field 'submit' => type => 'Submit';

sub validate {
   my $self  = shift;
   my $rs    = $self->context->model($self->item_class);
   my $field = $self->field('name');
   my $name  = $field->value;
   my $user  = $rs->find({ name => $name });

   return $field->add_error('User [_1] unknown', $name) unless $user;

   my $passwd = $self->field('password');

   try   {
      $user->authenticate($passwd->value);
      $self->log->info("Form.login: User ${name} logged in") if $self->has_log;
   }
   catch {
      $passwd->add_error($_->original);
      $self->log->alert($_) if $self->has_log;
   };

   return;
}

use namespace::autoclean -except => META;

1;
