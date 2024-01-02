package MCat::Form::Tag;

use HTML::Forms::Constants qw( FALSE META TRUE );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Model::DBIC';
with    'HTML::Forms::Role::Defaults';

has '+title'        => default => 'Tag';
has '+info_message' => default => 'Create or edit tags';

has_field 'name', required => TRUE;

has_field 'submit' => type => 'Button';

use namespace::autoclean -except => META;

1;
