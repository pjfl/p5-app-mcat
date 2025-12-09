package MCat::Object::View::Class;

use HTML::StateTable::Constants qw( FALSE NUL TRUE );
use Moo;

extends 'MCat::Object::View';

sub build_results {
   my $self    = shift;
   my $results = [];
   my $table   = $self->table;
   my $source  = $table->context->model($table->result_class)->result_source;

   for my $colname ($source->columns) {
      my $info = $source->columns_info->{$colname};
      my $name = $info->{label} // ucfirst $colname;

      next unless $self->_table_wants($info->{data_type});

      push @{$results}, $self->result_class->new(
         name => $name, value => $colname
      );
   }

   return $results;
}

my $_typemap = {
   bool     => { boolean => TRUE },
   datetime => { timestamp => TRUE },
   numeric  => {
      bigint => TRUE, float => TRUE, int => TRUE, integer => TRUE,
      real   => TRUE, smallint => TRUE
   },
   text     => { char => TRUE, varchar => TRUE }
};

sub _table_wants {
   my ($self, $have) = @_;

   return TRUE unless $self->table->has_data_type && $self->table->data_type;

   my $wanted = lc $self->table->data_type;

   $have = lc $have // NUL; $have =~ s{ \( .* \) \z }{}mx;

   return TRUE if $wanted eq $have or exists $_typemap->{$wanted}->{$have};

   return FALSE;
}

use namespace::autoclean;

1;
