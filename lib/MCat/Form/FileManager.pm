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

   my $file      = $self->file;
   my @parts     = split m{ / }mx, $file->scrub($self->field('name')->value);
   my $filename  = pop @parts;
   my $directory = join '/', @parts;

   try {
      my $to   = $file->directory($directory)->child($filename);
      my $meta = { owner => $self->context->session->username };

      throw 'Already exists' if $to->exists;

      if ($self->operation eq 'mkpath') {
         $to->mkpath;
         $file->add_meta($directory, $filename, $meta);
      }
      elsif ($self->operation eq 'copy' or $self->operation eq 'move') {
         my $selected = $self->selected_path;

         throw 'Nothing selected' unless $selected;

         my $from = $file->directory->catfile($selected);

         if ($self->operation eq 'copy') {
            $from->copy($to);
            $file->add_meta($directory, $filename, $meta);
         }
         else {
            $file->unshare_file($from);
            $from->move($to);
            $file->move_meta($from, $directory, $filename, $meta);
            $file->share_file($to) if $file->get_shared($directory, $filename);
         }
      }
      else { throw 'Operation [_1] unknown', [$self->operation] }
   }
   catch { $self->add_form_error(blessed $_ ? $_->original : $_) };

   return;
}

use namespace::autoclean -except => META;

1;
