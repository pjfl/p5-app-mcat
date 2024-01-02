package MCat::Form::Artist;

use HTML::Forms::Constants qw( FALSE META TRUE );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Model::DBIC';
with    'HTML::Forms::Role::Defaults';

has '+title'        => default => 'Artist';
has '+info_message' => default => 'Create or edit artists';
has '+item_class'   => default => 'Artist';

has_field 'name', required => TRUE;

has_field 'tags' => type => 'Select', multiple => TRUE, size => 4;

has_field 'active' => type => 'Boolean';

has_field 'upvotes' => type => 'Integer';

has_field 'submit' => type => 'Button';

use namespace::autoclean -except => META;

1;
