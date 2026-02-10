package MCat::Form::List;

use HTML::Forms::Constants qw( FALSE META TRUE USERID );
use HTML::Forms::Types     qw( Int );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Model::DBIC';
with    'HTML::Forms::Role::Defaults';

has '+title'              => default => 'Edit List';
has '+form_wrapper_class' => default => sub { ['narrow'] };
has '+info_message'       => default => 'You know what to do';
has '+item_class'         => default => 'List';

has_field 'name' => required => TRUE;

has_field 'description';

has_field 'owner' => type => 'Hidden';

sub default_owner {
   my $self    = shift;
   my $context = $self->context;

   return $context && $context->can('session')
      ? $context->session->id : USERID;
}

has_field 'core_table' => type => 'Select', label => 'Table', required => TRUE;

sub options_table {
   my $self     = shift;
   my $field    = $self->field('core_table');
   my $accessor = $field->parent->full_accessor if $field->parent;
   my $options  = $self->lookup_options($field, $accessor);

   return [ map { ucfirst } @{$options} ];
}

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
      my $view = $context->uri_for_action('list/view', [$self->item->id]);

      $self->field('view')->href($view->as_string);
      $self->field('submit')->add_wrapper_class(['inline', 'right']);
      $self->field('core_table')->disabled(TRUE);
      $self->field('core_table')->required(FALSE);
   }
   else { $self->field('view')->inactive(TRUE) }

   return;
};

use namespace::autoclean -except => META;

1;
