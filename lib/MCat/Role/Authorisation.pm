package MCat::Role::Authorisation;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE NUL TRUE );
use MCat::Util             qw( includes redirect );
use Unexpected::Functions  qw( throw NoUserRole );
use Moo::Role;

sub is_authorised {
   my ($self, $context, $action) = @_;

   throw 'No action: ' . caller unless $action;

   my $role = _get_action_auth($context, $action) // 'edit';

   return TRUE if $role eq 'none';

   my $session = $context->session;

   return $self->_redirect2login($context) unless $session->authenticated;

   return TRUE if $role eq 'view';

   my $user_role = $session->role or throw NoUserRole, [$session->username];

   return TRUE if $user_role eq 'admin';

   return TRUE if $user_role eq 'manager' and $role eq 'edit';

   return TRUE if $user_role eq $role;

   return $self->_redirect2unauthorised($context);
}

sub method_args {
   my ($self, $context, $action, $uri_args) = @_;

   my $captures = _get_captures($context, $action);

   return $uri_args unless $captures;

   my $method_args = [];

   for (1 .. $captures) {
      my $arg = shift @{$uri_args};

      last unless defined $arg;

      push @{$method_args}, $arg;
   }

   return $method_args;
}

# Private methods
sub _redirect2login {
   my ($self, $context) = @_;

   my $action  = $self->config->default_actions->{login};
   my $login   = $context->uri_for_action($action);
   my $wanted  = $context->request->uri;
   my $session = $context->session;

   # Redirect to wanted on successful login. Only set wanted to "legit" uris
   $session->wanted("${wanted}") if !$session->wanted
      && !$wanted->query_form('navigation')
      && _get_nav_label($context, $self->can($context->endpoint // NUL))
      && !includes $context->endpoint, [qw(login logout register)];

   $context->stash(redirect $login, ['Authentication required']);

   return FALSE;
}

sub _redirect2unauthorised {
   my ($self, $context) = @_;

   my $action = $self->config->default_actions->{unauthorised};

   $context->stash(redirect $context->uri_for_action($action),['Unauthorised']);

   return FALSE;
}

# Private functions
sub _get_action_auth {
   my ($context, $action) = @_;

   return unless $action;

   my $attr = eval { $context->get_attributes($action) };

   return $attr->{Auth}->[-1] if $attr && defined $attr->{Auth};

   return;
}

sub _get_captures {
   my ($context, $action) = @_;

   return unless $action;

   my $attr = eval { $context->get_attributes($action) };

   return $attr->{Capture}->[-1] if $attr && defined $attr->{Capture};

   return;
}

sub _get_nav_label {
   my ($context, $action) = @_;

   return unless $action;

   my $attr = eval { $context->get_attributes($action) };

   return $attr->{Nav}->[-1] if $attr && defined $attr->{Nav};

   return;
}

use namespace::autoclean;

1;
