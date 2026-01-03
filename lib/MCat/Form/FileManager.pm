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

   return $self->file->to_path($value);
}

sub validate {
   my $self = shift;

   return unless $self->validated;

   my $context    = $self->context;
   my $name       = $self->field('name');
   my ($pathname) = reverse split m{ / }mx, $self->file->scrub($name->value);
   my $directory  = $self->file->directory($self->directory);
   my $operation  = $self->operation;

   try {
      my $to    = $directory->child($pathname);
      my $owner = $context->session->username;

      throw 'Already exists' if $to->exists;

      if ($operation eq 'mkpath') {
         $to->mkpath;
         $self->file->add_meta($owner, $self->directory, $pathname);
      }
      elsif ($operation eq 'copy' or $operation eq 'move') {
         my $selected = $self->selected_path;

         throw 'Nothing selected' unless $selected;

         my $from = $self->file->directory->catfile($selected);

         if ($operation eq 'copy') {
            $from->copy($to);
            $self->file->add_meta($owner, $self->directory, $pathname);
         }
         else {
            $self->file->unshare_file($$from);
            $from->move($to);
            $self->file->move($owner, $self->directory, $from, $pathname);
            $self->file->share_file($to)
               if $self->file->get_shared($self->directory, $pathname);
         }
      }
      else { throw "Operation '${operation}' unknown" }
   }
   catch { $self->add_form_error(blessed $_ ? $_->original : $_) };

   return;
}

use namespace::autoclean -except => META;

1;
