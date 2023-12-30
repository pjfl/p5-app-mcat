package MCat::API::Object;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE TRUE );
use HTML::Forms::Types     qw( Str );
use Unexpected::Functions  qw( throw );
use DateTime::TimeZone;
use Moo;
use MCat::Navigation::Attributes; # Will do namespace cleaning

has 'name' => is => 'ro', isa => Str, required => TRUE;

sub get : Auth('view') {
   my ($self, $context, @args) = @_;

   my $object;

   if ($self->name eq 'list_name') {
      my $list_id = $context->request->query_parameters->{list_id};

      $object = $context->model('List')->find($list_id)->name;
   }
   elsif ($self->name eq 'timezones') {
      $object = [DateTime::TimeZone->all_names];
   }
   else { throw 'Object [_1] unknown api attribute name', [$self->name] }

   $context->stash(json => { $self->name => $object });
   return;
}

1;
