package MCat::Filter::Node::Rule::Data::InList;

use HTML::Forms::Constants qw( FALSE TRUE );
use MCat::Filter::Types    qw( FilterList );
use Moo;

extends 'MCat::Filter::Node::Rule';

has 'list' => is => 'ro', isa => FilterList, required => TRUE;

sub _to_abstract {
   my ($self, $args) = @_;

   my $column = $args->{table}->key_name || 'id';

   return $column => { -in => $self->_rhs_value($args) };
}

sub _rhs_value {
   my ($self, $args) = @_;

   my $list_id = $self->list->value($args);
   my $schema  = $args->{table}->result_source->schema;
   my $rs      = $schema->resultset($args->{table}->relation);
   my $options = { columns => [$args->{table}->key_name || 'id'] };

   return $rs->search({ list_id => $list_id }, $options)->as_query;
}

1;
