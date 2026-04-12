package MCat::Role::Authorisation;

use MCat::Constants        qw( EXCEPTION_CLASS FALSE NUL TRUE );
use Class::Usul::Cmd::Util qw( includes );
use MCat::Util             qw( redirect );
use Moo::Role;

sub is_authorised {
   my ($self, $context, $action) = @_;

   return $self->_unauthorised($context, 'No action ' . caller) unless $action;

   my $code_groups = _get_auth_for_action($context, $action);
   my $code_role   = shift @{$code_groups} || 'edit';

   return TRUE if $code_role eq 'none';

   my $session = $context->session;

   return $self->_redirect2login($context) unless $session->authenticated;

   my $valid_ip = $self->_validate_ip($context);

   return $self->_unauthorised($context, 'Bad IP Address') unless $valid_ip;

   my $user_role = $session->role;

   return $self->_unauthorised($context, 'No user role') unless $user_role;

   return TRUE if $user_role eq 'admin';

   if ($code_role eq 'view' or $user_role eq $code_role) {
      return TRUE unless $code_groups->[0];

      for my $user_group (@{$session->groups}) {
         return TRUE if includes $user_group, $code_groups;
      }
   }

   return $self->_unauthorised($context, 'Not Allowed');
}

sub method_args {
   my ($self, $context, $action, $uri_args) = @_;

   my $capture = _get_capture_for_action($context, $action);

   return $uri_args unless $capture;

   my $method_args = [];

   for (1 .. $capture) {
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
      && _get_nav_for_action($context, $self->can($context->endpoint // NUL))
      && !includes $context->endpoint, [qw(login logout register)];

   $context->stash(redirect $login, ['Authentication required']);

   return FALSE;
}

sub _unauthorised {
   my ($self, $context, $reason) = @_;

   my $action = $self->config->default_actions->{unauthorised};

   $context->stash(redirect $context->uri_for_action($action), [$reason]);

   return FALSE;
}

sub _validate_ip {
   my ($self, $context) = @_;

   my $request = $context->request;
   my $session = $context->session;

   return TRUE if $request->remote_address eq $session->address;

   return FALSE;
}

# Private functions
sub _get_auth_for_action {
   my ($context, $action) = @_;

   my $attr = eval { $context->get_attributes($action) };

   return [@{$attr->{Auth}}] if $attr && defined $attr->{Auth};

   return [];
}

sub _get_capture_for_action {
   my ($context, $action) = @_;

   return unless $action;

   my $attr = eval { $context->get_attributes($action) };

   return $attr->{Capture}->[-1] if $attr && defined $attr->{Capture};

   return;
}

sub _get_nav_for_action {
   my ($context, $action) = @_;

   return unless $action;

   my $attr = eval { $context->get_attributes($action) };

   return $attr->{Nav}->[-1] if $attr && defined $attr->{Nav};

   return;
}

use namespace::autoclean;

1;
