package MCat::Filter::Type::Date::Relative;

use HTML::Forms::Constants qw( FALSE TRUE );
use HTML::Forms::Types     qw( Bool Int );
use Moo;

extends 'MCat::Filter::Type::Date';

has 'days', is => 'ro', isa => Int, required => TRUE;

has 'months', is => 'ro', isa => Int, required => TRUE;

has 'past', is => 'ro', isa => Bool, required => TRUE;

has 'years', is => 'ro', isa => Int, required => TRUE;

sub value {
   my ($self, $args) = @_;

   my $interval = $self->_value($args);

   my $date; $date = $args->{date} if $args->{date};

   if ($self->has_time_zone) {
      my $timezone = $self->time_zone;

      return "(timezone('${timezone}', '${date}')::timestamp + '${interval}'::interval)::timestamp"
         if $date;

      return "(date_trunc('day', timezone('${timezone}', current_timestamp)) + '${interval}'::interval)";
   }

   return "('${date}'::timestamp + '${interval}'::interval)::date" if $date;

   return "(current_date::timestamp + '${interval}'::interval)::date";
}

sub _value {
   my $self   = shift;
   my $format = $self->past
      ? '-%syears -%smonths -%sdays' : '%syears %smonths %sdays';

   return sprintf $format, $self->years, $self->months, $self->days;
}

use namespace::autoclean;

1;
