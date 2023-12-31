package MCat::Schema::Result::Role;

use overload '""' => sub { $_[0]->_as_string },
             '+'  => sub { $_[0]->_as_number }, fallback => 1;

use Crypt::Eksblowfish::Bcrypt qw( bcrypt en_base64 );
use HTML::Forms::Constants     qw( EXCEPTION_CLASS FALSE TRUE );
use MCat::Util                 qw( digest urandom );
use Unexpected::Functions      qw( throw AccountInactive IncorrectPassword
                                   PasswordExpired );
use DBIx::Class::Moo::ResultClass;

my $class  = __PACKAGE__;
my $result = 'MCat::Schema::Result';

$class->table('public.role');

$class->add_columns(
   id => {
      data_type         => 'integer',
      is_nullable       => FALSE,
      is_auto_increment => TRUE,
      label             => 'Role ID'
   },
   name => { data_type => 'text', is_nullable => FALSE, label => 'Name' },
);

$class->set_primary_key('id');

$class->add_unique_constraint('role_name_uniq', ['name']);

$class->has_many('users' => "${result}::User", 'role_id');

# Private methods
sub _as_number {
   return $_[0]->id;
}

sub _as_string {
   return $_[0]->name;
}

1;
