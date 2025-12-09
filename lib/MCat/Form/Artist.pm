package MCat::Form::Artist;

use HTML::Forms::Constants qw( FALSE META NUL TRUE );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Model::DBIC';
with    'HTML::Forms::Role::Defaults';

has '+name'               => default => 'Artist';
has '+form_element_class' => default => sub { ['narrow'] };
has '+title'              => default => 'Artist';
has '+info_message'       => default => 'Create or edit artists';
has '+item_class'         => default => 'Artist';

has_field 'name', required => TRUE;

has_field 'tags' => type => 'Select', multiple => TRUE, size => 4;

has_field 'active' => type => 'Boolean';

has_field 'upvotes' =>
   type                => 'PosInteger',
   validate_inline     => TRUE,
   validate_when_empty => TRUE;

has_field 'view' =>
   type          => 'Link',
   label         => 'View',
   element_class => ['form-button pageload'],
   wrapper_class => ['input-button', 'inline'];

has_field 'submit' => type => 'Button';

after 'after_build_fields' => sub {
   my $self    = shift;
   my $context = $self->context;

   if ($self->item) {
      my $view = $context->uri_for_action('artist/view', [$self->item->id]);

      $self->field('view')->href($view->as_string);
      $self->field('submit')->add_wrapper_class(['inline', 'right']);
   }
   else { $self->field('view')->inactive(TRUE) }

   return;
};

use namespace::autoclean -except => META;

1;
