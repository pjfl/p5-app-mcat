package MCat::Form::Track;

use HTML::Forms::Constants qw( FALSE META TRUE );
use HTML::Forms::Types     qw( Int );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Model::DBIC';
with    'HTML::Forms::Role::Defaults';

has '+title'               => default => 'Track';
has '+default_wrapper_tag' => default => 'fieldset';
has '+do_form_wrapper'     => default => TRUE;
has '+info_message'        => default => 'You know what to do';

has 'cdid' => is => 'ro', isa => Int, required => TRUE;

has_field 'cdid' => type => 'Hidden';

has_field 'title' => required => 1;

has_field 'submit' => type => 'Submit';

sub default_cdid {
   my $self = shift; return $self->cdid;
}

use namespace::autoclean -except => META;

1;
