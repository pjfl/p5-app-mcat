package MCat::Schema::Result::List;

use HTML::Forms::Constants qw( FALSE TRUE );
use DBIx::Class::Moo::ResultClass;

my $class  = __PACKAGE__;
my $result = 'MCat::Schema::Result';

$class->table('list');

$class->add_columns(
   id => {
      data_type         => 'integer',
      is_auto_increment => TRUE,
      is_nullable       => FALSE,
      label             => 'List ID'
   },
   name          => { data_type => 'text', is_nullable => FALSE },
   description   => { data_type => 'text', is_nullable => TRUE },
   owner_user_id => {
      data_type   => 'integer',
      is_nullable => FALSE,
      label       => 'Owner',
      display     => 'owner.name',
   },
   table_id      => {
      data_type   => 'integer',
      is_nullable => FALSE,
      label       => 'Table',
      display     => 'core_table.name',
   },
);

$class->set_primary_key('id');

$class->add_unique_constraint(
   'list_name_owner_user_uniq', ['name', 'owner_user_id']
);

$class->belongs_to('owner', "${result}::User", {
   'foreign.id' => 'self.owner_user_id'
});

$class->belongs_to('core_table', "${result}::Table", {
   'foreign.id' => 'self.table_id'
});

$class->has_many(
   'artists' => "${result}::ListArtist", { 'foreign.list_id' => 'self.id' }
);

$class->has_many(
   'cds' => "${result}::ListCd", { 'foreign.list_id' => 'self.id' }
);

$class->has_many(
   'tracks' => "${result}::ListTrack", { 'foreign.list_id' => 'self.id' }
);

1;
