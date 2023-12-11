package MCat::Schema::Result::Filter;

use HTML::Forms::Constants qw( FALSE TRUE );
use Class::Usul::Cmd::Util qw( now_dt );
use JSON::MaybeXS          qw( decode_json encode_json );
use Type::Utils            qw( class_type );
use MCat::Filter::Parser;
use DBIx::Class::Moo::ResultClass;

my $class  = __PACKAGE__;
my $result = 'MCat::Schema::Result';

$class->load_components('InflateColumn::DateTime');
$class->table('filter');

$class->add_columns(
   id => {
      data_type         => 'integer',
      is_auto_increment => TRUE,
      is_nullable       => FALSE,
      label             => 'Filter ID',
   },
   name          => { data_type => 'text', is_nullable => FALSE },
   description   => { data_type => 'text', is_nullable => TRUE },
   owner_user_id => { data_type => 'integer', is_nullable => FALSE },
   table_id      => { data_type => 'integer', is_nullable => FALSE },
   filter_json   => { data_type => 'text', is_nullable => FALSE },
   filter_search => { data_type => 'text', is_nullable => FALSE },
   updated       => {
      cell_traits => ['Date'],
      data_type   => 'timestamp',
      is_nullable => FALSE,
      label       => 'Last Updated',
      timezone    => 'UTC',
   },
);

$class->set_primary_key('id');

$class->add_unique_constraint(
   'filter_name_owner_user_uniq', ['name', 'owner_user_id']
);

$class->belongs_to('owner', "${result}::User", {
   'foreign.id' => 'self.owner_user_id'
});

$class->belongs_to('core_table', "${result}::Table", {
   'foreign.id' => 'self.table_id'
});

$class->inflate_column('filter_search', {
   deflate => sub { encode_json(shift) },
   inflate => sub { decode_json(shift) },
});

has 'parser' =>
   is      => 'lazy',
   isa     => class_type('MCat::Filter::Parser'),
   default => sub {
      my $self   = shift;
      my $config = $self->result_source->schema->config;

      if ($config->can('filter_config')) { $config = $config->filter_config }
      else { $config = {} }

      return MCat::Filter::Parser->new(config => $config);
   };

sub insert {
   my $self = shift;

   $self->_inflate_columns;

   return $self->next::method;
}

sub parse {
   my ($self, $json) = @_;

   $json //= $self->filter_json;

   return $self->parser->parse($json);
}

sub update {
   my ($self, $columns) = @_;

   $self->set_inflated_columns($columns) if $columns;

   $self->_inflate_columns;

   return $self->next::method;
}

# Private methods
sub _inflate_columns {
   my $self    = shift;
   my $columns = { $self->get_inflated_columns };
   my $filter  = $self->parse($columns->{filter_json});

   $columns->{filter_search} = $filter->search;
   $columns->{updated} = now_dt;
   $self->set_inflated_columns($columns);
   return;
}

1;
