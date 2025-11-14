package MCat::Schema::Result::BugComment;

use MCat::Constants qw( FALSE SQL_NOW TRUE );
use DBIx::Class::Moo::ResultClass;

my $class  = __PACKAGE__;
my $result = 'MCat::Schema::Result';

$class->table('bug_comments');

$class->add_columns(
   id => {
      data_type         => 'integer',
      extra             => { unsigned => TRUE },
      is_auto_increment => TRUE,
      is_nullable       => FALSE,
      is_numeric        => TRUE,
      label             => 'Comment ID'
   },
   bug_id => {
      data_type   => 'integer',
      extra       => { unsigned => TRUE },
      is_nullable => FALSE,
      is_numeric  => TRUE,
   },
   user_id => {
      data_type   => 'integer',
      display     => 'owner.name',
      extra       => { unsigned => TRUE },
      is_nullable => FALSE,
      is_numeric  => TRUE,
      label       => 'Owner',
   },
   created => {
      data_type     => 'timestamp',
      cell_traits   => ['DateTime'],
      is_nullable   => FALSE,
      set_on_create => TRUE,
      timezone      => 'UTC',
   },
   updated => {
      data_type   => 'timestamp',
      cell_traits => ['DateTime'],
      is_nullable => TRUE,
      timezone    => 'UTC',
   },
   comment => { data_type => 'text', is_nullable => FALSE },
);

$class->set_primary_key('id');

$class->belongs_to('bug' => "${result}::Bug", 'bug_id');

$class->belongs_to('owner' => "${result}::User", 'user_id');

$class->has_many('attachments' => "${result}::BugAttachment", 'comment_id');

sub insert {
   my $self    = shift;
   my $columns = { $self->get_inflated_columns };

   $columns->{created} = SQL_NOW;
   $self->set_inflated_columns($columns);

   return $self->next::method;
}

sub update {
   my ($self, $columns) = @_;

   $self->set_inflated_columns($columns) if $columns;

   $columns = { $self->get_inflated_columns };
   $columns->{updated} = SQL_NOW;
   $self->set_inflated_columns($columns);
   return $self->next::method;
}

use namespace::autoclean;

1;
