package MCat::Form::Table;

use HTML::Forms::Constants qw( FALSE META TRUE );
use HTML::Forms::Types     qw( Int );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Model::DBIC';
with    'HTML::Forms::Role::Defaults';

has '+title'               => default => 'Table';
has '+default_wrapper_tag' => default => 'fieldset';
has '+do_form_wrapper'     => default => TRUE;
has '+info_message'        => default => 'You know what to do';
has '+item_class'          => default => 'Table';

has_field 'name' => required => TRUE;

has_field 'relation' => required => TRUE;

has_field 'submit' => type => 'Submit';

use namespace::autoclean -except => META;

1;
