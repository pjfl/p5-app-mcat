package MCat::Form::Artist;

use HTML::Forms::Constants qw( FALSE META TRUE );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Model::DBIC';
with    'HTML::Forms::Role::Defaults';

has '+title'               => default => 'Artist';
has '+default_wrapper_tag' => default => 'fieldset';
has '+do_form_wrapper'     => default => TRUE;
has '+info_message'        => default => 'You know what to do';

has_field 'name', required => 1;

has_field 'tags' => type => 'Select', multiple => TRUE, size => 4;

has_field 'active' => type => 'Boolean';

has_field 'upvotes' => type => 'Integer';

has_field 'submit' => type => 'Submit';

use namespace::autoclean -except => META;

1;
