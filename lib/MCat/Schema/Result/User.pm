package MCat::Schema::Result::User;

use overload '""' => sub { $_[0]->_as_string },
             '+'  => sub { $_[0]->_as_number }, fallback => 1;

use HTML::Forms::Constants     qw( EXCEPTION_CLASS FALSE NUL TRUE );
use HTML::Forms::Types         qw( Bool HashRef );
use Crypt::Eksblowfish::Bcrypt qw( bcrypt en_base64 );
use MCat::Util                 qw( digest truncate urandom );
use Scalar::Util               qw( blessed );
use Unexpected::Functions      qw( throw AccountInactive IncorrectAuthCode
                                   IncorrectPassword PasswordDisabled
                                   PasswordExpired Unspecified );
use Auth::GoogleAuth;
use DBIx::Class::Moo::ResultClass;

my $class  = __PACKAGE__;
my $result = 'MCat::Schema::Result';

$class->table('public.user');

$class->add_columns(
   id => {
      data_type => 'integer', is_nullable => FALSE, is_auto_increment => TRUE,
      label => 'User ID'
   },
   name => { data_type => 'text', is_nullable => FALSE, label => 'User Name' },
   email => {
      data_type => 'text', is_nullable => FALSE, label => 'Email Address'
   },
   role_id => {
      data_type => 'integer', is_nullable => FALSE,
      label => 'Role', cell_traits => ['Capitalise'], display => 'role.name'
   },
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
);

$class->set_primary_key('id');

$class->add_unique_constraint('user_email_uniq', ['email']);

$class->add_unique_constraint('user_name_uniq', ['name']);

$class->belongs_to('role' => "${result}::Role", 'role_id');

$class->has_many('filters' => "${result}::Filter", 'owner_user_id');

$class->has_many('lists' => "${result}::List", 'owner_user_id');

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

has 'authenticate_only' => is => 'ro', isa => Bool, default => FALSE;

has 'profile_value' => is => 'lazy', isa => HashRef, default => sub {
   my $self    = shift;
   my $profile = $self->profile;

   return $profile ? $profile->value : {};
};

has 'totp_authenticator' => is => 'lazy', default => sub {
   my $self = shift;

   return Auth::GoogleAuth->new({
      issuer => $self->result_source->schema->config->prefix,
      key_id => $self->name,
      secret => $self->totp_secret,
   });
};

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
sub assert_can_email {
   my $self = shift;

   throw 'User [_1] has no email address', [$self] unless $self->email;
   throw 'User [_1] has an example email address', [$self]
      unless $self->can_email;

   return;
}

sub authenticate {
   my ($self, $password, $code, $for_update) = @_;

   throw AccountInactive, [$self] unless $self->active;

   throw PasswordDisabled, [$self] if _is_disabled $self->password;

   throw PasswordExpired, [$self] if $self->password_expired && !$for_update;

   throw Unspecified, ['Password'] unless $password;

   my $encrypted = bcrypt($password, _get_salt $self->password);

   throw IncorrectPassword, [$self] unless $self->password eq $encrypted;

   return TRUE if !$self->totp_secret || $for_update;

   throw Unspecified, ['Auth. Code'] unless $code;

   throw IncorrectAuthCode, [$self]
      unless $self->totp_authenticator->verify($code);

   return TRUE;
}

sub can_email {
   my $self = shift;

   return FALSE unless $self->email;
   return FALSE if $self->email =~ m{ \@example\.com \z }mx;
   return TRUE;
}

sub enable_2fa {
   my ($self, $value) = @_; return $self->_profile('enable_2fa', $value);
}

sub encrypt_password {
   my ($self, $password) = @_;

   my $lf = $self->result_source->schema->config->user->{load_factor};

   return bcrypt($password, _new_salt '2a', $lf);
}

sub execute {
   my ($self, $method) = @_;

   return FALSE unless exists { enable_2fa => TRUE }->{$method};

   return $self->$method();
}

sub insert {
   my $self    = shift;
   my $columns = { $self->get_inflated_columns };

   $self->_encrypt_password($columns, 'password');

   return if $self->authenticate_only;

   return $self->next::method;
}

sub mobile_phone {
   my ($self, $value) = @_; return $self->_profile('mobile_phone', $value);
}

sub postcode {
   my ($self, $value) = @_; return $self->_profile('postcode', $value);
}

sub set_password {
   my ($self, $old, $new) = @_;

   $self->authenticate($old, NUL, TRUE);
   $self->password($new);
   $self->password_expired(FALSE);
   return $self->update;
}

sub set_totp_secret {
   my ($self, $enabled) = @_;

   my $current = $self->totp_secret ? TRUE : FALSE;

   return $self->totp_secret(substr digest(urandom())->b64digest, 0, 16)
      if $enabled && !$current;

   return $self->totp_secret(NUL) if $current && !$enabled;

   return $self->totp_secret;
}

sub to_session {
   my ($self, $session) = @_;

   return unless $session && blessed $session;

   my $profile = $self->profile_value;

   for my $key (grep { $_ ne 'authenticated' } keys %{$profile}) {
      my $value       = $profile->{$key};
      my $value_class = blessed $value;

      if ($value_class && $value_class eq 'JSON::PP::Boolean') {
         $value = "${value}" ? TRUE : FALSE;
      }

      $session->$key($value) if defined $value && $session->can($key);
   }

   $session->email($self->email)     if $session->can('email');
   $session->id($self->id)           if $session->can('id');
   $session->role($self->role->name) if $session->can('role');
   $session->username($self->name)   if $session->can('username');

   return;
}

sub totp_secret {
   my ($self, $value) = @_; return $self->_profile('totp_secret', $value);
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

sub _profile {
   my ($self, $key, $value) = @_;

   my $profile = $self->profile_value;

   if (defined $value) {
      $profile->{$key} = $value;

      my $rs = $self->result_source->schema->resultset('Preference');

      $rs->update_or_create({
         name => 'profile', user_id => $self->id, value => $profile
      });
   }

   return $profile->{$key};
}

use namespace::autoclean;

1;
