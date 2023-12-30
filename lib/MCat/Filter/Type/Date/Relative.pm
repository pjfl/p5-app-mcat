package MCat::Filter::Type::Date::Relative;

use HTML::Forms::Constants qw( FALSE NUL TRUE );
use HTML::Forms::Types     qw( Bool Int );
use Moo;

extends 'MCat::Filter::Type::Date';

has 'days', is => 'ro', isa => Int, required => TRUE;

has 'months', is => 'ro', isa => Int, required => TRUE;

has 'past', is => 'ro', isa => Bool, required => TRUE;

has 'years', is => 'ro', isa => Int, required => TRUE;

sub value {
   my ($self, $args) = @_;

   my $interval = "'" . $self->_value($args) . "'::interval";
   my $date; $date = $args->{date} if $args->{date};
   my $value;

   if ($self->has_time_zone) {
      my $timezone = $self->time_zone;

      if ($date) {
         $value = "(timezone('${timezone}', '${date}')::timestamp + ${interval})";
      }
      else {
         $value = "(date_trunc('day', timezone('${timezone}', current_timestamp)) + ${interval})";
      }
   }
   elsif ($date) {
      $value = "('${date}'::timestamp + ${interval})";
   }
   else {
      $value = "(current_date::timestamp + ${interval})";
   }

   return $value, $self->years, $self->months, $self->days;
}

sub _value {
   my $self = shift;

   return $self->past ? '-?years -?months -?days' : '?years ?months ?days';
}

use namespace::autoclean;

1;
