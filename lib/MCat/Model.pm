package MCat::Model;

use HTML::Forms::Constants qw( FALSE NUL TRUE );
use MCat::Util             qw( formpost );
use Type::Utils            qw( class_type );
use HTML::Forms::Manager;
use HTML::StateTable::Manager;
use Web::Components::Navigation;
use Moo;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'Web::Components::Model';
with    'MCat::Role::Authorisation';
with    'MCat::Role::Schema';

=pod

=encoding utf-8

=head1 Name

MCat::Model - Model base class

=head1 Synopsis

   use Moo;

   extends 'MCat::Model';

=head1 Description

Model base class

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<form>

An instance of the L<form factory|HTML::Forms::Manager> class

=cut

has 'form' =>
   is      => 'lazy',
   isa     => class_type('HTML::Forms::Manager'),
   handles => { new_form => 'new_with_context' },
   default => sub {
      my $self     = shift;
      my $appclass = $self->config->appclass;

      return HTML::Forms::Manager->new({
         namespace      => "${appclass}::Form",
         renderer_class => 'HTML::Forms::Render::EmptyDiv',
         schema         => $self->schema,
      });
   };

=item C<table>

An instance of the L<table factory|HTML::StateTable::Manager> class

=cut

has 'table' =>
   is      => 'lazy',
   isa     => class_type('HTML::StateTable::Manager'),
   handles => { new_table => 'new_with_context' },
   default => sub {
      my $self     = shift;
      my $appclass = $self->config->appclass;

      return HTML::StateTable::Manager->new({
         log       => $self->log,
         namespace => "${appclass}::Table",
         view_name => 'table',
      });
   };

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item C<new_form>

   $form = $self->new_form('MyForm', { context => $context });

Creates new L<forms|HTML::Forms>

=item C<new_table>

   $table = $self->new_table('MyTable', { context => $context });

Creates new L<tables|HTML::StateTable>

=item C<root>

   $self->root($context);

Creates and stashes an instance of L<Web::Components::Navigation>

Navigation methods C<menu>, C<list>, and C<item> are used to build the
context sensitive menu data

This method adds menu items for the C<control> menu

=cut

sub root : Auth('none') {
   my ($self, $context) = @_;

   my $options = { context => $context, model => $self };
   my $nav     = Web::Components::Navigation->new($options);
   my $actions = $self->config->default_actions;
   my $session = $context->session;

   $context->stash($self->navigation_key => $nav);
   $nav->list('bugs')->item('bug/create')->list('_control');

   if ($session->authenticated) {
      $nav->menu('bugs')->item('bug/list');
      $nav->item($actions->{changes}) if $actions->{changes};
      $nav->item($actions->{password}, [$session->id]);
      $nav->item($actions->{profile}, [$session->id]);
      $nav->item($actions->{totp}, [$session->id]) if $session->enable_2fa;
      $nav->item(formpost, $actions->{logout});
   }
   else {
      $nav->item($actions->{login});
      $nav->item($actions->{register}, []) if $self->config->registration;
      $nav->item($actions->{password}, [$session->id]);
   }

   return;
}

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<HTML::Forms::Manager>

=item L<HTML::StateTable::Manager>

=item L<Web::Components::Navigation>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=MCat.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2025 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
