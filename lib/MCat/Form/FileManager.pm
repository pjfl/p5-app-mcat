package MCat::Form::FileManager;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE META NUL TRUE );
use HTML::Forms::Types     qw( Maybe Str );
use Scalar::Util           qw( blessed );
use Unexpected::Functions  qw( throw );
use Try::Tiny;
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms';
with    'HTML::Forms::Role::Defaults';
with    'MCat::Role::FileMeta';

has '+do_form_wrapper' => default => FALSE;
has '+name'            => default => 'FileManager';
has '+info_message'    => default => 'Enter new name';
has '+no_update'       => default => TRUE;

has 'directory' => is => 'ro', isa => Maybe[Str];

has 'operation' => is => 'ro', isa => Str, required => TRUE;

has_field 'name' => required => TRUE;

has_field 'selected' => type => 'Hidden';

after 'before_build_fields' => sub {
   my $self = shift;

   $self->add_form_element_class('filemanager');
   return;
};

sub selected_path {
   my $self  = shift;
   my $value = $self->field('selected')->value or return;

   return $self->meta_to_path($value);
}

sub validate {
   my $self = shift;

   return if $self->result->has_errors;

   my $context    = $self->context;
   my $name       = $self->field('name');
   my ($pathname) = reverse split m{ / }mx, $self->meta_scrub($name->value);
   my $directory  = $self->meta_directory($context, $self->directory);
   my $operation  = $self->operation;

   try {
      throw 'Already exists' if $directory->child($pathname)->exists;

      if ($operation eq 'mkpath') {
         $directory->child($pathname)->mkpath;
         $self->meta_add($context, $self->directory, $pathname);
      }
      elsif ($operation eq 'copy' or $operation eq 'move') {
         my $selected = $self->selected_path;

         throw 'Nothing selected' unless $selected;

         my $from = $self->meta_directory($context)->catfile($selected);

         $from->$operation($directory->catfile($pathname));

         if ($operation eq 'copy') {
            $self->meta_add($context, $self->directory, $pathname);
         }
         else { $self->meta_move($context, $self->directory, $from, $pathname) }
      }
      else { throw "Operation '${operation}' unknown" }
   }
   catch { $self->add_form_error(blessed $_ ? $_->original : $_) };

   return;
}

use namespace::autoclean -except => META;

1;
