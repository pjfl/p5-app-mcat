package MCat::Schema::Result::User;

use strictures;
use overload '""' => sub { $_[0]->_as_string },
             '+'  => sub { $_[0]->_as_number }, fallback => 1;
use parent 'DBIx::Class::Core';

use Crypt::Eksblowfish::Bcrypt qw( bcrypt en_base64 );
use HTML::Forms::Constants     qw( EXCEPTION_CLASS FALSE TRUE );
use MCat::Util                 qw( digest local_tz truncate urandom );
use Unexpected::Functions      qw( throw AccountInactive IncorrectPassword
                                   PasswordDisabled PasswordExpired );

my $class  = __PACKAGE__;
my $result = 'MCat::Schema::Result';

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
      display => sub { truncate shift->result->password, 20 }
   },
   password_expired => {
      data_type => 'boolean', is_nullable => FALSE, default => FALSE,
      label => 'Password Expired', cell_traits => ['Bool']
   },
   role_id => {
      data_type => 'integer', is_nullable => FALSE,
      label => 'Role', cell_traits => ['Capitalise'], display => 'role.name'
   },
);

$class->set_primary_key('id');

$class->add_unique_constraint('user_name_uniq', ['name']);

$class->belongs_to('role' => "${result}::Role", 'role_id');

$class->has_many('preferences' => "${result}::Preference", 'user_id');

$class->might_have('profile' => "${result}::Preference", sub {
   my $args    = shift;
   my $foreign = $args->{foreign_alias};
   my $self    = $args->{self_alias};

   return {
      "${foreign}.user_id" => { -ident => "${self}.id" },
      "${foreign}.name"    => { '=' => 'profile' }
   };
});

# Private functions
sub _get_salt ($) {
   my @parts = split m{ [\$] }mx, $_[0];

   $parts[-1] = substr $parts[-1], 0, 22;

   return join '$', @parts;
}

sub _is_disabled ($) {
   return $_[0] =~ m{ \* }mx ? TRUE : FALSE;
}

sub _is_encrypted ($) {
   return $_[0] =~ m{ \A \$\d+[a]?\$ }mx ? TRUE : FALSE;
}

sub _new_salt ($$) {
   my ($type, $lf) = @_;

   my $token = digest(urandom())->hexdigest;

   return "\$${type}\$${lf}\$" . (en_base64(pack('H*', substr($token, 0, 32))));
}

# Public methods
sub authenticate {
   my ($self, $password, $for_update) = @_;

   throw AccountInactive, [$self] unless $self->active;

   throw PasswordDisabled, [$self] if _is_disabled $self->password;

   throw PasswordExpired, [$self] if $self->password_expired && !$for_update;

   my $encrypted = bcrypt($password, _get_salt $self->password);

   throw IncorrectPassword, [$self] unless $self->password eq $encrypted;

   return TRUE;
}

sub encrypt_password {
   my ($self, $password) = @_;

   my $lf = $self->result_source->schema->config->user->{load_factor};

   return bcrypt($password, _new_salt '2a', $lf);
}

sub insert {
   my $self    = shift;
   my $columns = { $self->get_inflated_columns };

   $self->_encrypt_password($columns, 'password');

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
   $self->_encrypt_password($columns, 'password');

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
   my ($self, $columns, $column_name) = @_;

   my $password = $columns->{$column_name} or return;

   return if _is_disabled $password or _is_encrypted $password;

   $columns->{password} = $self->encrypt_password($password);
   $self->set_inflated_columns($columns);
   return;
}

use namespace::autoclean;

1;
