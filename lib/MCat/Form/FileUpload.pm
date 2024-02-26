package MCat::Form::FileUpload;

use HTML::Forms::Constants qw( FALSE META NUL TRUE );
use HTML::Forms::Types     qw( Int Str );
use File::DataClass::IO    qw( io );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms';
with    'HTML::Forms::Role::Defaults';
with    'MCat::Role::FileMeta';

has '+do_form_wrapper' => default => FALSE;
has '+info_message'    => default => 'Enter file name';
has '+no_update'       => default => TRUE;

has 'destination' => is => 'rw', isa => Str, default => NUL;

has 'max_copies' => is => 'ro', isa => Int, default => 9;

has_field 'file' => label => NUL, type => 'Upload';

after 'before_build_fields' => sub {
   my $self = shift;

   $self->add_form_element_class('filemanager');
   return;
};

sub validate {
   my $self = shift;

   return if $self->result->has_errors;

   my $context   = $self->context;
   my $directory = $context->get_body_parameters->{directory};
   my $request   = $context->request;

   $self->add_form_error('Attribute [_1] not found', 'upload object')
      unless $request->has_upload;

   my $upload = $request->upload;

   $self->add_form_error($upload->reason) unless $upload->is_upload;

   my $filename = $request->query_parameters->{name} || $upload->filename;

   $filename = $self->meta_scrub($filename);

   my ($extn) = $filename =~ m{ \. (.+) \z }mx;
   my $config = $context->config->filemanager;
   my $extns  = $config->{extensions} || 'csv|txt';

   return $self->add_form_error('File type [_1] not allowed', ".${extn}")
      unless $extn =~ m{ \A (?: $extns ) \z }mx;

   my $base = $self->meta_directory($context, $directory);
   my $dest = $base->catfile($filename)->assert_filepath;

   if ($dest->exists) {
      $filename = $self->_next_filename($base, $filename);
      $dest     = $filename ? $base->catfile($filename) : NUL;
   }

   if ($dest) {
      io($upload->path)->copy($dest);
      $self->meta_add($context, $directory, $filename);
      $self->destination($dest->abs2rel($self->meta_directory($context)));
   }

   return;
}

sub _next_filename {
   my ($self, $directory, $filename) = @_;

   my ($basename, $extn) = $filename =~ m{ \A ([^\.]+) \. (.+) \z }mx;

   for my $count (1 .. $self->max_copies) {
      $filename = "${basename}(${count}).${extn}";

      return $filename unless $directory->catfile($filename)->exists;
   }

   return;
}

use namespace::autoclean -except => META;

1;
