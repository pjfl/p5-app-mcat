package MCat::Schema::Result::ListCd;

use HTML::Forms::Constants qw( FALSE TRUE );
use DBIx::Class::Moo::ResultClass;

my $class  = __PACKAGE__;
my $result = 'MCat::Schema::Result';

$class->table('list.cd');

$class->add_columns(
   cdid    => { data_type => 'integer' },
   list_id => { data_type => 'integer' },
);

$class->set_primary_key(qw( cdid list_id ));

$class->belongs_to(
   'cds' => "${result}::Cd", { 'foreign.cdid' => 'self.cdid' }
);

$class->belongs_to(
   'list' => "${result}::List", { 'foreign.id' => 'self.list_id' }
);

1;
