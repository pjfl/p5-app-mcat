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

has_field 'view' =>
   type          => 'Link',
   label         => 'View',
   element_class => ['form-button pageload'],
   wrapper_class => ['input-button', 'inline'];

has_field 'submit' => type => 'Button';

sub default_cdid {
   my $self = shift; return $self->cdid;
}

after 'after_build_fields' => sub {
   my $self    = shift;
   my $context = $self->context;

   if ($self->item) {
      my $view = $context->uri_for_action('track/view', [$self->item->id]);

      $self->field('view')->href($view->as_string);
      $self->field('submit')->add_wrapper_class(['inline', 'right']);
   }
   else { $self->field('view')->inactive(TRUE) }

   return;
};

use namespace::autoclean -except => META;

1;
