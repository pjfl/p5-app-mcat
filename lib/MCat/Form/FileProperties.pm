package MCat::Form::FileProperties;

use HTML::Forms::Constants qw( FALSE META NUL TRUE );
use HTML::Forms::Types     qw( Str );
use File::DataClass::Types qw( Path );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms';
with    'HTML::Forms::Role::Defaults';
with    'MCat::Role::FileMeta';

has '+do_form_wrapper' => default => FALSE;
has '+info_message'    => default => 'Update file properties';
has '+no_update'       => default => TRUE;

has 'directory' => is => 'ro', isa => Str;

has 'path' =>
   is      => 'lazy',
   isa     => Path,
   default => sub {
      my $self = shift;
      my $dir  = $self->meta_directory($self->context, $self->directory);

      return $dir->child($self->selected);
   };

has '_selected' => is => 'ro', isa => Str, init_arg => 'selected';

has 'selected' =>
   is       => 'lazy',
   isa      => Str,
   init_arg => undef,
   default  => sub {
      my $self       = shift;
      my $path       = $self->meta_to_path($self->_selected);
      my ($selected) = reverse split m{ / }mx, $path;

      return $selected;
   };

has 'type' =>
   is      => 'lazy',
   isa     => Str,
   default => sub { shift->path->is_file ? 'file' : 'directory' };

has_field 'shared' => type => 'Boolean';

sub default_shared {
   my $self    = shift;
   my $form    = $self->form;
   my $context = $form->context;

   return $form->meta_get_shared($context, $form->directory, $form->selected);
}

has_field 'cancel' =>
   html_name     => 'submit',
   label         => 'Cancel',
   type          => 'Button',
   value         => 'cancel',
   wrapper_class => ['inline input-button left'];

has_field 'submit' =>
   type          => 'Button',
   wrapper_class => ['inline input-button right'];

after 'before_build_fields' => sub {
   my $self = shift;

   $self->add_form_element_class('filemanager');
   return;
};

after 'after_build_fields' => sub {
   my $self = shift;

   if ($self->type eq 'directory') {
      push @{$self->field('shared')->wrapper_class}, 'hide';
      push @{$self->field('submit')->wrapper_class}, 'hide';
      $self->info_message('No directory properties to update');
   }

   my $renderer = $self->context->config->wcom_resources->{table_renderer};
   my $js       = "${renderer}.tables.filemanager.modal.close()";

   $self->field('cancel')->element_attr->{javascript} = { onclick => $js };
   return;
};

sub validate {
   my $self = shift;

   return unless $self->validated;

   my $context = $self->context;
   my $shared  = $self->field('shared')->value;

   $self->meta_set_shared($context, $self->directory, $self->selected, $shared);

   if ($shared) { $self->meta_share($context, $self->path) }
   else { $self->meta_unshare($context, $self->path) }

   return;
}

use namespace::autoclean -except => META;

1;
