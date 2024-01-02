package MCat::Form::Cd;

use HTML::Forms::Constants qw( FALSE META TRUE );
use HTML::Forms::Types     qw( Int );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Model::DBIC';
with    'HTML::Forms::Role::Defaults';

has '+title'        => default => 'CD';
has '+info_message' => default => 'You know what to do';

has 'artistid' => is => 'ro', isa => Int, required => TRUE;

has_field 'artistid' => type => 'Hidden';

has_field 'title' => required => TRUE;

has_field 'year' => type => 'Date', required => TRUE;

has_field 'submit' => type => 'Button';

sub default_artistid {
   my $self = shift; return $self->artistid;
}

use namespace::autoclean -except => META;

1;
