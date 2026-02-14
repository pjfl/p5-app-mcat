package MCat::Schema::Result::List;

use overload '""' => sub { $_[0]->_as_string },
             '+'  => sub { $_[0]->_as_number }, fallback => 1;

use HTML::Forms::Constants qw( FALSE NUL TRUE );
use Class::Usul::Cmd::Util qw( now_dt );
use MCat::Object::Link;
use Try::Tiny;
use DBIx::Class::Moo::ResultClass;

my $class  = __PACKAGE__;
my $result = 'MCat::Schema::Result';

$class->load_components('InflateColumn::DateTime');
$class->table('list');

$class->add_columns(
   id => {
      data_type         => 'integer',
      hidden            => TRUE,
      is_auto_increment => TRUE,
      is_nullable       => FALSE,
      label             => 'List ID'
   },
   name          => { data_type => 'text', is_nullable => FALSE },
   description   => { data_type => 'text', is_nullable => TRUE },
   owner_user_id => {
      data_type   => 'integer',
      display     => 'owner.name',
      is_nullable => FALSE,
      label       => 'Owner',
   },
   table_id      => {
      data_type   => 'integer',
      display     => 'core_table.name',
      is_nullable => FALSE,
      label       => 'Table',
   },
   status => { data_type => 'text', is_nullable => TRUE },
   updated => {
      cell_traits => ['DateTime'],
      data_type   => 'timestamp',
      is_nullable => TRUE,
      label       => 'Last Updated',
      timezone    => 'UTC',
   },
   filter_id => {
      data_type   => 'integer',
      display     => \&_filter_link,
      is_nullable => TRUE,
      label       => 'Filter',
   },
   count => { data_type => 'integer', is_nullable => TRUE },
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

$class->belongs_to('filter' => "${result}::Filter", {
   'foreign.id' => 'self.filter_id'
});

sub apply_filter {
   my ($self, $filter) = @_;

   my $schema      = $self->result_source->schema;
   my $table_rs    = $schema->resultset($self->core_table->name);
   my $filtered_rs = $table_rs->search($filter->to_where);
   my $options     = {
      count     => 0,
      filter_id => $filter->id,
      status    => 'Updating',
      updated   => now_dt
   };

   $self->update($options);

   try {
      $schema->txn_do(sub {
         $self->empty_list;

         while (my $included = $filtered_rs->next) {
            $included->create_related('lists', { list_id => $self->id });
            $options->{count}++;
         }
      });
      $options->{status} = 'Complete';
   }
   catch {
      $options->{status} = 'Failed';
      $options->{count}  = 0;
   };

   $options->{updated} = now_dt;
   $self->update($options);

   return $options->{count};
}

sub delete {
   my $self = shift;

   $self->empty_list;
   $self->next::method;
   return;
}

sub empty_list {
   my $self    = shift;
   my $schema  = $self->result_source->schema;
   my $join_rs = $schema->resultset($self->core_table->relation);

   $join_rs->search({ list_id => $self->id })->delete;
   return TRUE;
}

sub queue_update {
   my ($self, $filter_id, $username) = @_;

   my $list_id = $self->id;
   my $schema  = $self->result_source->schema;
   my $program = $schema->config->bin->catfile('mcat-cli');
   my $options = "-o list_id=${list_id} -o filter_id=${filter_id} " .
                 "-o recipient=${username}";
   my $command = "${program} ${options} update_list";
   my $args    = { command => $command, name => 'update_list' };

   return $schema->resultset('Job')->create($args);
}

# Private methods
sub _as_number {
   return shift->id;
}

sub _as_string {
   my $self = shift;

   return sprintf '%s (%s records)', $self->name, $self->count // 0;
}

# Private functions
sub _filter_link {
   my $table  = shift;
   my $filter = $table->result->filter or return NUL;
   my $link   = $table->context->uri_for_action('filter/view', [$filter->id]);

   return MCat::Object::Link->new({ link => $link , value => $filter->name });
}

1;
