package MCat::Schema::Result::BugAttachment;

use MCat::Constants qw( FALSE SQL_NOW TRUE );
use DBIx::Class::Moo::ResultClass;

my $class  = __PACKAGE__;
my $result = 'MCat::Schema::Result';

$class->load_components( qw( TimeStamp ) );

$class->table('bug_attachments');

$class->add_columns(
   id => {
      data_type         => 'integer',
      extra             => { unsigned => TRUE },
      is_auto_increment => TRUE,
      is_nullable       => FALSE,
      is_numeric        => TRUE,
      label             => 'Attachment ID'
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
   comment_id => {
      data_type   => 'integer',
      extra       => { unsigned => TRUE },
      is_nullable => TRUE,
      is_numeric  => TRUE,
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
   path => { data_type => 'text', is_nullable => FALSE },
);

$class->set_primary_key('id');

$class->belongs_to('bug' => "${result}::Bug", 'bug_id');

$class->belongs_to('owner' => "${result}::User", 'user_id');

$class->belongs_to('comment' => "${result}::BugComment", 'comment_id');

sub content_path {
   my ($self, $file) = @_;

   return $file->directory($self->bug_id)->catfile($self->path);
}

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
