package MCat::Role::Authorisation;

use HTML::Forms::Constants       qw( EXCEPTION_CLASS FALSE TRUE );
use MCat::Util                   qw( redirect );
use Unexpected::Functions        qw( throw NoUserRole );
use MCat::Navigation::Attributes qw();
use Moo::Role;

around 'allowed' => sub {
   my ($orig, $self, $context, $moniker, $method) = @_;

   my $models = $context->models;
   my $action = "${moniker}/${method}";
   my $attr   = MCat::Navigation::Attributes->attr_for($models, $action);

   return $orig->($self, $context, $moniker, $method)
      if $self->is_authorised($context, $attr);

   return;
};

sub is_authorised {
   my ($self, $context, $attr) = @_;

   my $role = $attr->{Auth}->[-1] // 'edit';

   return TRUE if $role eq 'none';

   my $session = $context->session;

   unless ($session->authenticated) {
      my $location = $context->uri_for_action('page/login');
      my $wanted   = $context->request->uri;

      $session->wanted("${wanted}")
         unless $session->wanted || $wanted->query_form('navigation')
         || $location eq substr $wanted, 0, length $location;

      $context->stash(redirect $location, ['Authentication required']);
      return FALSE;
   }

   return TRUE if $role eq 'view';

   my $user_role = $session->role or throw NoUserRole, [$session->username];

   return TRUE if $role eq $user_role or $user_role eq 'admin';

   $context->stash(redirect $context->uri_for_action('page/access_denied'), []);
   return FALSE;
}

use namespace::autoclean;

1;
