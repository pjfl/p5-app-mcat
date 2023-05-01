package MCat::Form::Login;

use HTML::Forms::Constants qw( FALSE META TRUE );
use MCat::Util             qw( redirect );
use Try::Tiny;
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms';
with    'HTML::Forms::Role::Defaults';

has '+title'               => default => 'Login';
has '+default_wrapper_tag' => default => 'fieldset';
has '+do_form_wrapper'     => default => TRUE;
has '+info_message'        => default => 'Enter your username and password';
has '+is_html5'            => default => TRUE;
has '+item_class'          => default => 'User';

has 'log' => is => 'ro', predicate => 'has_log';

has_field 'name', required => TRUE, title => 'Enter your user name';

has_field 'password', type => 'Password', required => TRUE;

has_field 'submit' => type => 'Submit';

sub validate {
   my $self = shift;

   return if $self->result->has_errors;

   my $field   = $self->field('name');
   my $name    = $field->value;
   my $context = $self->context;
   my $session = $context->session;
   my $rs      = $context->model($self->item_class);
   my $user    = $rs->find({ name => $name });

   return $field->add_error('User [_1] unknown', $name) unless $user;

   my $passwd = $self->field('password');

   try {
      $user->authenticate($passwd->value);
      $session->authenticated(TRUE);
      $session->id($user->id);
      $session->role($user->role->name);
      $session->username($user->name);
   }
   catch {
      my $exception = $_;

      $passwd->add_error($exception->original);
      $session->authenticated(FALSE);

      if ($exception->class eq 'PasswordExpired') {
         my $changep = $context->uri_for_action(
            'page/change_password', [$user->id]
         );

         $context->stash( redirect $changep, [$exception->original] );
         $context->stash('redirect')->{level} = 'alert' if $self->has_log;
      }
      else {
         $self->log->alert($exception, $self->context) if $self->has_log;
      }
   };

   if ($session->authenticated and my $profile = $user->profile) {
      my $value = $profile->value;

      $session->skin($value->{skin}) if defined $value->{skin};
      $session->timezone($value->{timezone}) if defined $value->{timezone};
   }

   return;
}

use namespace::autoclean -except => META;

1;
