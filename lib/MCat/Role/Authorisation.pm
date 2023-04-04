package MCat::Role::Authorisation;

use HTML::Forms::Constants       qw( EXCEPTION_CLASS FALSE TRUE );
use MCat::Util                   qw( redirect );
use Unexpected::Functions        qw( throw NoUserRole );
use MCat::Navigation::Attributes qw();
use Moo::Role;

around 'allowed' => sub {
   my ($orig, $self, $context, $moniker, $method) = @_;

   my $models  = $context->models;
   my $action  = "${moniker}/${method}";
   my $attr    = MCat::Navigation::Attributes->attr_for($models, $action);
   my $role    = $attr->{Auth}->[-1] // 'edit';

   return $orig->($self, $context, $moniker, $method) if $role eq 'none';

   my $session = $context->session;

   unless ($session->authenticated) {
      my $location = $context->uri_for_action('page/login');

      $context->stash(redirect $location, ['Authentication required']);
      return;
   }

   return $orig->($self, $context, $moniker, $method) if $role eq 'view';

   my $user_role = $session->role or throw NoUserRole, [$session->username];

   return $orig->($self, $context, $moniker, $method)
      if $role eq $user_role or $user_role eq 'admin';

   $context->stash(redirect $context->uri_for_action('page/access_denied'), []);
   return;
};

use namespace::autoclean;

1;
