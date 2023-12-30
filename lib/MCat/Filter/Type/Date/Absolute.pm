package MCat::Filter::Type::Date::Absolute;

use HTML::Forms::Constants qw( FALSE TRUE );
use MCat::Filter::Types    qw( AbsoluteDate );
use Moo;

extends 'MCat::Filter::Type::Date';

has 'date' => is => 'ro', isa => AbsoluteDate, required => TRUE;

sub value {
   return '?', shift->date;
}

1;
