package MCat::Context;

use attributes ();

use MCat::Constants         qw( EXCEPTION_CLASS FALSE NUL TRUE );
use Class::Usul::Cmd::Types qw( ConfigProvider Int Str );
use Class::Usul::Cmd::Util  qw( includes );
use HTML::Forms::Util       qw( get_token verify_token );
use Ref::Util               qw( is_arrayref is_coderef is_hashref );
use Scalar::Util            qw( blessed );
use Type::Utils             qw( class_type );
use Unexpected::Functions   qw( throw NoMethod UnknownModel );
use MCat::Response;
use Moo;

extends 'Web::Components::Context';

=pod

=encoding utf-8

=head1 Name

MCat::Context - Per request context object

=head1 Synopsis

   use MCat::Context;

=head1 Description

Per request context object

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item config

=cut

has 'config' => is => 'ro', isa => ConfigProvider, required => TRUE;

=item icons_uri

=cut

has 'icons_uri' =>
   is      => 'lazy',
   isa     => class_type('URI'),
   default => sub {
      my $self = shift;

      return $self->request->uri_for($self->config->icons);
   };

=item response

=cut

has 'response' =>
   is      => 'ro',
   isa     => class_type('MCat::Response'),
   default => sub { MCat::Response->new };

=item time_zone

=cut

has 'time_zone' =>
   is      => 'lazy',
   isa     => Str,
   default => sub { shift->session->timezone };

=item token_lifetime

=cut

has 'token_lifetime' =>
   is      => 'lazy',
   isa     => Int,
   default => sub { shift->config->token_lifetime };

has '+_stash' =>
   default => sub {
      my $self   = shift;
      my $prefix = $self->config->prefix;
      my $skin   = $self->session->skin || $self->config->skin;

      return {
         chartlibrary       => 'js/highcharts.js',
         favicon            => 'img/favicon.ico',
         javascript         => "js/${prefix}.js",
         session_updated    => $self->session->updated,
         skin               => $skin,
         stylesheet         => "css/${prefix}-${skin}.css",
         theme              => $self->session->theme,
         verification_token => $self->verification_token,
         version            => MCat->VERSION,
      };
   };

with 'MCat::Role::Schema';
with 'MCat::Role::Authentication';

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item feature

=cut

sub feature {
   my ($self, $feature) = @_;

   return includes $feature, $self->session->features;
}

=item get_attributes

=cut

sub get_attributes {
   my ($self, $action) = @_;

   return unless $action;

   return attributes::get($action) // {} if is_coderef $action;

   my ($moniker, $method) = split m{ / }mx, $action;

   return {} unless $moniker && $method;

   my $component = $self->models->{$moniker}
      or throw UnknownModel, [$moniker];
   my $coderef = $component->can($method)
      or throw NoMethod, [blessed $component, $method];

   return attributes::get($coderef) // {};
}

=item is_authorised

=cut

sub is_authorised {
   my ($self, $actionp) = @_;

   return FALSE unless $actionp;

   my ($moniker) = split m{ / }mx, $actionp;

   return FALSE unless $moniker;

   my $model = $self->models->{$moniker};

   return FALSE unless $model;

   my $authorised = $model->is_authorised($self, $actionp);

   $self->clear_redirect;
   return $authorised;
}

=item method_chain

=cut

sub method_chain {
   my ($self, $action) = @_;

   return $self->_action_lookup($action, 'methods');
}

=item model

=cut

sub model {
   my ($self, $rs_name) = @_;

   return $rs_name ? $self->schema->resultset($rs_name) : undef;
}

=item res

=cut

sub res { shift->response }

=item uri_for_action

=cut

sub uri_for_action {
   my ($self, $action, $args, @params) = @_;

   my $uri    = $self->_action_lookup($action, 'uri');
   my $uris   = is_arrayref $uri ? $uri : [ $uri ];
   my $params = is_hashref $params[0] ? $params[0] : {@params};

   for my $candidate (@{$uris}) {
      my $n_stars =()= $candidate =~ m{ \* }gmx;

      if ($n_stars == 2 and $candidate =~ m{ / \* \* }mx) {
         ($uri = $candidate) =~ s{ / \* \* }{}mx;
         last;
      }

      if ($n_stars == 2 and $candidate =~ m{ / \* \. \* }mx) {
         ($uri = $candidate) =~ s{ / \* \. \* }{}mx;
         last;
      }

      next if $n_stars != 0 and $n_stars > scalar @{$args // []};

      $uri = $candidate;

      while ($uri =~ m{ \* }mx) {
         my $arg = shift @{$args // []};

         last unless defined $arg;

         $uri =~ s{ \* }{$arg}mx;
      }

      last;
   }

   $uri .= delete $params->{extension} if exists $params->{extension};

   return $self->request->uri_for($uri, $args, $params);
}

=item verification_token

=cut

sub verification_token {
   my $self = shift;

   return get_token $self->token_lifetime, $self->session->serialise;
}

=item verify_form_post

=cut

sub verify_form_post {
   my $self  = shift;
   my $token = $self->body_parameters->{_verify} // NUL;

   return verify_token $token, $self->session->serialise;
}

# Private methods
sub _action_lookup {
   my ($self, $action, $key) = @_;

   for my $moniker (keys %{$self->controllers}) {
      my $controller = $self->controllers->{$moniker};

      next unless $controller->can('action_path_map');

      my $map = $controller->action_path_map;

      return $map->{$action}->{$key} if exists $map->{$action};
   }

   return $action;
}

use namespace::autoclean;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Web::Components::Context>

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
