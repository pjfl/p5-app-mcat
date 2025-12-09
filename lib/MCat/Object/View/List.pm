package MCat::Object::View::List;

use HTML::StateTable::Constants qw( NUL );
use Moo;

extends 'MCat::Object::View';

sub build_results {
   my $self    = shift;
   my $results = [];
   my $table   = $self->table;
   my $rs      = $table->context->model('List');

   for my $list ($rs->search({ table_id => $table->table_id })->all) {
      push @{$results}, $self->result_class->new(
         name => $list->name, value => $list->id
      );
   }

   return $results;
}

use namespace::autoclean;

1;
