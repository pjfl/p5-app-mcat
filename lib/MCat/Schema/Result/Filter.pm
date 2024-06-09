package MCat::Schema::Result::Filter;

use HTML::Forms::Constants qw( FALSE NUL TRUE );
use Class::Usul::Cmd::Util qw( now_dt );
use Type::Utils            qw( class_type );
use HTML::Filter::Parser;
use DBIx::Class::Moo::ResultClass;

use Data::Dumper;

$Data::Dumper::Terse = TRUE;

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
   name => { data_type => 'text', is_nullable => FALSE },
   description => { data_type => 'text', is_nullable => TRUE },
   owner_user_id => {
      data_type   => 'integer', is_nullable => FALSE, label => 'Owner',
      cell_traits => ['Capitalise'], display => 'owner.name'
   },
   table_id => {
      data_type => 'integer', is_nullable => FALSE, label => 'Table',
      display   => 'core_table.name'
   },
   updated => {
      cell_traits => ['Date'],
      data_type   => 'timestamp',
      is_nullable => FALSE,
      label       => 'Last Updated',
      timezone    => 'UTC',
   },
   filter_json   => {
      data_type => 'text', is_nullable => FALSE, label => 'Editor Data'
   },
   filter_search => {
      data_type => 'text', is_nullable => FALSE, label => 'Abstract'
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

has 'parser' =>
   is      => 'lazy',
   isa     => class_type('HTML::Filter::Parser'),
   default => sub {
      my $self   = shift;
      my $config = $self->result_source->schema->config;

      if ($config->can('filter_config')) { $config = $config->filter_config }
      else { $config = {} }

      return HTML::Filter::Parser->new(config => $config);
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

sub to_sql {
   my $self    = shift;
   my $schema  = $self->result_source->schema;
   my $rs      = $schema->resultset($self->core_table->name);
   my $columns = { columns => [$self->core_table->key_name] };
   my ($query, @bindv) = @{${$rs->search($self->to_where, $columns)->as_query}};

   return [$query, Dumper(\@bindv)];
}

sub to_where {
   my ($self, $json) = @_;

   return { $self->parse($json)->to_abstract({ table => $self->core_table }) };
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

   if ($columns->{filter_json}) {
      my $dumped = Dumper($self->to_where($columns->{filter_json}));

      $dumped =~ s{ [\n] }{}gmx;
      $columns->{filter_search} = $dumped;
   }
   else {
      $columns->{filter_json} = NUL;
      $columns->{filter_search} = NUL;
   }

   $columns->{updated} = now_dt;
   $self->set_inflated_columns($columns);
   return;
}

1;
