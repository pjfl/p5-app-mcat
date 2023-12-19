package MCat::Filter::Node::Rule::Date::Equals;

use Moo;

extends 'MCat::Filter::Node::Rule::Date';

has '+_operator' => default => '=';

sub _to_where {
   my ($self, $args) = @_;

   my $max = my $min = $self->date->value;
   my $lhs = $self->_field_to_where($args);

   return { $lhs => { $self->_operator => $min } }
      unless $self->date->has_time_zone;

   if ($self->date->type eq 'Type.Date.Relative') {
      my $next_day = "(current_timestamp + '1days'::interval)";

      $max =~ s{ current_timestamp }{$next_day}mx;
   }

   return {
      '-and' => [
         "${lhs}::timestamp" => { '>=' => $min },
         "${lhs}::timestamp" => { '<' => $max }
      ]
   };
}

use namespace::autoclean;

1;
