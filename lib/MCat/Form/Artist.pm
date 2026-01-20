package MCat::Form::Artist;

use HTML::Forms::Constants qw( FALSE META NUL TRUE );
use HTML::Forms::Types     qw( Str );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Model::DBIC';
with    'HTML::Forms::Role::Defaults';

has '+info_message' => default => 'Create or edit artists';
has '+item_class'   => default => 'Artist';
has '+name'         => default => 'Artist';
has '+title'        => default => 'Edit Artist';

has '_icons' =>
   is      => 'lazy',
   isa     => Str,
   default => sub { shift->context->icons_uri->as_string };

has_field 'name', required => TRUE;

has_field 'tags' =>
   type       => 'SelectMany',
   display_as => '...',
   size       => 4,
   title      => 'Select Tags';

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

   $self->add_form_element_class('narrow');

   my $resources = $context->config->wcom_resources;
   my $field     = $self->field('tags');

   $field->icons($self->_icons);
   $field->form_util($resources->{form_util});
   $field->modal($resources->{modal});

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
