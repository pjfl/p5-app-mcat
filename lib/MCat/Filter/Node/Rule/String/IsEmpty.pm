package MCat::Filter::Node::Rule::String::IsEmpty;

use HTML::Forms::Constants qw( FALSE NUL );
use Moo;

extends 'MCat::Filter::Node::Rule::String';

has '+_operator' => default => '=';

has '+string' => required => FALSE;

sub _value {
   return NUL;
}

use namespace::autoclean;

1;
