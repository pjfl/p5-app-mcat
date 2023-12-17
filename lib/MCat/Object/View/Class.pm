package MCat::Object::View::Class;

use Moo;

extends 'MCat::Object::View';

sub build_results {
   my $self    = shift;
   my $results = [];
   my $table   = $self->table;
   my $source  = $table->context->model($table->result_class)->result_source;

   for my $colname ($source->columns) {
      my $info   = $source->columns_info->{$colname};
      my $traits = $info->{cell_traits} // [];
      my $name   = $info->{label} // ucfirst $colname;

      push @{$results}, MCat::Object::Result->new(
         name => $name, value => $colname
      );
   }

   return $results;
}

use namespace::autoclean;

1;
