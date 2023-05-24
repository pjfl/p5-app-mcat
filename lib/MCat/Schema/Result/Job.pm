package MCat::Schema::Result::Job;

use overload '""' => sub { $_[0]->_as_string },
             '+'  => sub { $_[0]->_as_number }, fallback => 1;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE NUL TRUE );
use MCat::Util             qw( now );
use DBIx::Class::Moo::ResultClass;

my $class  = __PACKAGE__;
my $result = 'MCat::Schema::Result';

$class->load_components('InflateColumn::DateTime');
$class->table('job');

$class->add_columns(
   id => {
      data_type => 'integer', is_nullable => FALSE, is_auto_increment => TRUE,
      label => 'Job ID'
   },
   name => { data_type => 'text', is_nullable => FALSE, label => 'Job Name' },
   created => {
      data_type => 'timestamp', is_nullable => TRUE, timezone => 'UTC',
      cell_traits => ['DateTime'], set_on_create => TRUE
   },
   updated => {
      data_type => 'timestamp', is_nullable => TRUE, timezone => 'UTC',
      cell_traits => ['DateTime']
   },
   run => {
      data_type => 'smallint', default_value => 0, is_nullable => FALSE,
      cell_traits => ['Numeric'], label => 'Run #'
   },
   max_runs => {
      data_type => 'smallint', default_value => 3, is_nullable => FALSE,
      cell_traits => ['Numeric'], label => 'Max. Runs'
   },
   period => {
      data_type => 'smallint', default_value => 300, is_nullable => FALSE,
      cell_traits => ['Numeric']
   },
   command => { data_type => 'text', is_nullable => FALSE, label => 'Command' },
);

$class->set_primary_key('id');

# Public methods
sub insert {
   my $self    = shift;
   my $columns = { $self->get_inflated_columns };

   $columns->{created} = now;
   $self->set_inflated_columns($columns);

   my $job       = $self->next::method;
   my $jobdaemon = $self->result_source->schema->context->jobdaemon;

   $jobdaemon->trigger if $jobdaemon->is_running;

   return $job;
}

sub label {
   return $_[0]->_as_string . ($_[0]->run ? '#' . $_[0]->run : NUL);
}

sub update {
   my ($self, $columns) = @_;

   $self->set_inflated_columns($columns) if $columns;

   $columns = { $self->get_inflated_columns };
   $columns->{updated} = now;
   $self->set_inflated_columns($columns);
   return $self->next::method;
}

# Private methods
sub _as_number {
   return $_[0]->id;
}

sub _as_string {
   return $_[0]->name . '-' . $_[0]->id;
}

1;
