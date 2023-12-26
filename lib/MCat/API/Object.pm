package MCat::API::Object;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE TRUE );
use HTML::Forms::Types     qw( Str );
use JSON::MaybeXS          qw( );
use Type::Utils            qw( class_type );
use Unexpected::Functions  qw( throw );
use DateTime::TimeZone;
use Moo;
use MCat::Navigation::Attributes; # Will do namespace cleaning

has 'name' => is => 'ro', isa => Str, required => TRUE;

has '_json' =>
   is      => 'ro',
   isa     => class_type(JSON::MaybeXS::JSON),
   default => sub { JSON::MaybeXS->new( convert_blessed => TRUE ) };

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
   else { throw 'Object [_1] unknown api type', [$self->name] }

   $context->stash(body => $self->_json->encode({ $self->name => $object }));
   return;
}

1;
