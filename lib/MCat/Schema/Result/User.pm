use utf8; # -*- coding: utf-8; -*-
package MCat::Schema::Result::User;

use strictures;
use overload '""' => sub { $_[0]->_as_string },
             '+'  => sub { $_[0]->_as_number }, fallback => 1;
use parent 'DBIx::Class::Core';

use Crypt::Eksblowfish::Bcrypt qw( bcrypt en_base64 );
use HTML::Forms::Constants     qw( EXCEPTION_CLASS FALSE TRUE );
use MCat::Util                 qw( digest urandom );
use Unexpected::Functions      qw( throw AccountInactive IncorrectPassword
                                   PasswordExpired );

my $class = __PACKAGE__;

$class->table('public.user');

$class->add_columns(
   id => {
      data_type => 'integer', is_nullable => FALSE, is_auto_increment => TRUE,
      label => 'User ID'
   },
   name => { data_type => 'text', is_nullable => FALSE, label => 'Name' },
   active => {
      data_type => 'boolean', is_nullable => FALSE, default => TRUE,
      label => 'Still Active', cell_traits => ['Bool']
   },
   password => {
      data_type => 'text', is_nullable => FALSE, label => 'Password',
      display => sub { _truncate(shift->result->password, 20) }
   },
   password_expired {
      data_type => 'boolean', is_nullable => FALSE, default => FALSE,
      label => 'Password Expired', cell_traits => ['Bool']
   },
   role_id {
      data_type => 'integer', is_nullable => FALSE,
      label => 'Role', display => 'role.name'
   }
);

$class->set_primary_key('id');

$class->add_unique_constraint('user_name_uniq', ['name']);

$class->belongs_to('role' => 'MCat::Schema::Result:Role', 'role_id');

# Private functions
sub _get_salt ($) {
   my @parts = split m{ [\$] }mx, $_[0];

   $parts[-1] = substr $parts[-1], 0, 22;

   return join '$', @parts;
}

sub _is_encrypted ($) {
   return $_[0] =~ m{ \A \$\d+[a]?\$ }mx ? TRUE : FALSE;
}

sub _new_salt ($$) {
   my ($type, $lf) = @_;

   my $token = digest(urandom())->hexdigest;

   return "\$${type}\$${lf}\$" . (en_base64(pack('H*', substr($token, 0, 32))));
}

sub _truncate ($;$) {
   my ($string, $length) = @_;

   $length //= 80;
   return substr($string, 0, $length - 1) . '…';
}

# Public methods
sub authenticate {
   my ($self, $password, $for_update) = @_;

   throw AccountInactive, [$self] unless $self->active;

   throw PasswordExpired, [$self] if $self->password_expired && !$for_update;

   throw IncorrectPassword, [$self]
      unless $self->password eq bcrypt($password, _get_salt $self->password);

   return TRUE;
}

sub insert {
   my $self    = shift;
   my $columns = { $self->get_inflated_columns };

   $self->_encrypt_password($columns, $columns->{password});

   return $self->next::method;
}

sub set_password {
   my ($self, $old, $new) = @_;

   $self->authenticate($old, TRUE);
   $self->password($new);
   $self->password_expired(FALSE);
   return $self->update;
}

sub update {
   my ($self, $columns) = @_;

   $self->set_inflated_columns($columns) if $columns;

   $columns = { $self->get_inflated_columns };
   $self->_encrypt_password($columns, $columns->{password});

   return $self->next::method;
}

# Private methods
sub _as_number {
   return $_[0]->id;
}

sub _as_string {
   return $_[0]->name;
}

sub _encrypt_password {
   my ($self, $columns, $password) = @_;

   if ($password && !_is_encrypted $password) {
      my $lf = $self->result_source->schema->config->user->{load_factor};

      $columns->{password} = bcrypt($password, _new_salt '2a', $lf);
      $self->set_inflated_columns($columns);
   }

   return;
}

1;
