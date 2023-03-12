package MCat::Form::Tag;

use HTML::Forms::Constants qw( FALSE META TRUE );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Model::DBIC';
with    'HTML::Forms::Role::Defaults';

has '+title'               => default => 'Tag';
has '+default_wrapper_tag' => default => 'fieldset';
has '+do_form_wrapper'     => default => TRUE;
has '+info_message'        => default => 'Create or edit tags';

has_field 'name', required => 1;

has_field 'submit' => type => 'Submit';

use namespace::autoclean -except => META;

1;
