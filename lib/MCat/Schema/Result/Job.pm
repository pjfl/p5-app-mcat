package MCat::Schema::Result::Job;

use overload '""' => sub { $_[0]->_as_string },
             '+'  => sub { $_[0]->_as_number }, fallback => 1;

use MCat::Constants qw( EXCEPTION_CLASS FALSE NUL SQL_NOW TRUE );
use MCat::Util      qw( dt_human );
use DBIx::Class::Moo::ResultClass;

my $class  = __PACKAGE__;
my $result = 'MCat::Schema::Result';

$class->load_components('InflateColumn::DateTime');
$class->table('job');

$class->add_columns(
   id => {
      data_type         => 'integer',
      is_nullable       => FALSE,
      is_auto_increment => TRUE,
      label             => 'Job ID',
   },
   name => { data_type => 'text', is_nullable => FALSE, label => 'Job Name' },
   created => {
      data_type     => 'timestamp',
      cell_traits   => ['DateTime'],
      is_nullable   => TRUE,
      set_on_create => TRUE,
      timezone      => 'UTC',
   },
   updated => {
      data_type   => 'timestamp',
      cell_traits => ['DateTime'],
      is_nullable => TRUE,
      timezone    => 'UTC',
   },
   run => {
      data_type     => 'smallint',
      cell_traits   => ['Numeric'],
      default_value => 0,
      is_nullable   => FALSE,
      label         => 'Run #',
   },
   max_runs => {
      data_type     => 'smallint',
      cell_traits   => ['Numeric'],
      default_value => 3,
      is_nullable   => FALSE,
      label         => 'Max. Runs',
   },
   period => {
      data_type     => 'smallint',
      cell_traits   => ['Numeric'],
      default_value => 300,
      display       => sub { dt_human shift->result->period },
      is_nullable   => FALSE,
   },
   command => { data_type => 'text', is_nullable => FALSE, label => 'Command' },
);

$class->set_primary_key('id');

# Public methods
sub insert {
   my $self    = shift;
   my $columns = { $self->get_inflated_columns };

   $columns->{created} = SQL_NOW;
   $self->set_inflated_columns($columns);

   my $job       = $self->next::method;
   my $jobdaemon = $self->result_source->schema->jobdaemon;

   $jobdaemon->trigger if $jobdaemon->is_running;

   return $job;
}

sub label {
   my $self = shift; return $self->_as_string . '#' . ($self->run + 1);
}

sub update {
   my ($self, $columns) = @_;

   $self->set_inflated_columns($columns) if $columns;

   $columns = { $self->get_inflated_columns };
   $columns->{updated} = SQL_NOW;
   $self->set_inflated_columns($columns);

   return $self->next::method;
}

# Private methods
sub _as_number {
   return shift->id;
}

sub _as_string {
   my $self = shift; return $self->name . '-' . $self->id;
}

1;
