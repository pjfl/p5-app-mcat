package MCat::Form::Track;

use HTML::Forms::Constants qw( FALSE META TRUE );
use HTML::Forms::Types     qw( Int );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Model::DBIC';
with    'HTML::Forms::Role::Defaults';

has '+title'        => default => 'Track';
has '+info_message' => default => 'You know what to do';

has 'cdid' => is => 'ro', isa => Int, required => TRUE;

has_field 'cdid' => type => 'Hidden';

has_field 'title' => required => TRUE;

has_field 'submit' => type => 'Button';

sub default_cdid {
   my $self = shift; return $self->cdid;
}

use namespace::autoclean -except => META;

1;
