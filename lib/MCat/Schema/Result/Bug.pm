package MCat::Schema::Result::Bug;

use MCat::Constants qw( BUG_STATE_ENUM FALSE SQL_NOW TRUE );
use DBIx::Class::Moo::ResultClass;

with 'MCat::Role::FileMeta';

my $class  = __PACKAGE__;
my $result = 'MCat::Schema::Result';

$class->table('bugs');

$class->add_columns(
   id => {
      data_type         => 'integer',
      extra             => { unsigned => TRUE },
      is_auto_increment => TRUE,
      is_nullable       => FALSE,
      is_numeric        => TRUE,
      label             => 'Bug ID'
   },
   title       => { data_type => 'text', is_nullable => FALSE },
   description => { data_type => 'text', is_nullable => FALSE },
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
   state       => {
      data_type     => 'enum',
      default_value => 'open',
      extra         => { list => BUG_STATE_ENUM },
      is_enum       => TRUE,
   },
   assigned_id => {
      data_type   => 'integer',
      display     => 'assigned.name',
      extra       => { unsigned => TRUE },
      is_nullable => TRUE,
      is_numeric  => TRUE,
      label       => 'Assigned',
   },
);

$class->set_primary_key('id');

$class->belongs_to('owner' => "${result}::User", 'user_id');

$class->belongs_to('assigned' => "${result}::User", 'assigned_id');

$class->has_many('comments' => "${result}::BugComment", 'bug_id');

$class->has_many('attachments' => "${result}::BugAttachment", 'bug_id');

has '+meta_config_attr' => default => 'bug_attachments';

sub delete {
   my $self = shift;

   $self->purge_attachments(TRUE);

   return $self->next::method;
}

sub insert {
   my $self    = shift;
   my $columns = { $self->get_inflated_columns };

   $columns->{created} = SQL_NOW;
   $self->set_inflated_columns($columns);

   return $self->next::method;
}

sub purge_attachments {
   my ($self, $for_delete) = @_;

   my $config = $self->result_source->schema->config;
   my $purged = [];
   my $map    = {};

   unless ($for_delete) {
      my @attachments = $self->attachments->all;

      for my $attachment (@attachments) {
         $map->{$attachment->path} = TRUE;
      }
   }

   my $attachment_dir = $self->meta_directory($config, $self->id);

   return FALSE unless $attachment_dir->exists;

   for my $file ($attachment_dir->all) {
      my $base = $file->basename;

      next if exists $map->{$base} or $base =~ m{ \A \. }mx;

      push @{$purged}, $base;
      $file->unlink;
   }

   return $purged->[0] ? $purged : FALSE;
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
