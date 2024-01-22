package MCat::Role::Authorisation;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE TRUE );
use MCat::Util             qw( redirect );
use Unexpected::Functions  qw( throw NoUserRole );
use Moo::Role;

sub is_authorised {
   my ($self, $context, $action) = @_;

   my $role = _get_auth_role($context, $action) // 'edit';

   return TRUE if $role eq 'none';

   my $session = $context->session;

   return _redirect2login($context, $action) unless $session->authenticated;

   return TRUE if $role eq 'view';

   my $user_role = $session->role or throw NoUserRole, [$session->username];

   return TRUE if $role eq 'edit' and $user_role eq 'manager';

   return TRUE if $role eq $user_role or $user_role eq 'admin';

   $context->stash(redirect $context->uri_for_action('page/access_denied'), []);

   return FALSE;
}

# Private functions
sub _get_auth_role {
   my ($context, $action) = @_;

   my $attr = eval { $context->get_attributes($action) };

   return $attr->{Auth}->[-1] if $attr && defined $attr->{Auth};

   return;
}

sub _get_nav_label {
   my ($context, $action) = @_;

   my $attr = eval { $context->get_attributes($action) };

   return $attr->{Nav}->[0] if $attr && defined $attr->{Nav};

   return;
}

sub _redirect2login {
   my ($context, $action) = @_;

   my $location = $context->uri_for_action('page/login');
   my $wanted   = $context->request->uri;
   my $session  = $context->session;

   # Redirect to wanted on successful login. Only set wanted to "legit" uris
   $session->wanted("${wanted}") unless $session->wanted
      || $wanted->query_form('navigation')
      || ($location eq substr $wanted, 0, length $location)
      || !_get_nav_label($context, $action);

   $context->stash(redirect $location, ['Authentication required']);

   return FALSE;
}

use namespace::autoclean;

1;
