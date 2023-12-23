package MCat::Filter::Node::Rule::Date::Equals;

use Moo;

extends 'MCat::Filter::Node::Rule::Date';

has '+_operator' => default => '=';

sub _to_abstract {
   my ($self, $args) = @_;

   return $self->next::method($args) unless $self->date->has_time_zone;

   my $max = my $min = $self->date->value;
   my $lhs = $self->field->value;

   if ($self->date->type eq 'Type.Date.Relative') {
      my $next_day = "(current_timestamp + '1days'::interval)";

      $max =~ s{ current_timestamp }{$next_day}mx;
   }

   return '-and' => [ $lhs => { '>=' => $min }, $lhs => { '<' => $max } ];
}

use namespace::autoclean;

1;
