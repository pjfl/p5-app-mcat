package MCat::Form::BugAttachment;

use HTML::Forms::Constants qw( FALSE META NUL TRUE );
use HTML::Forms::Types     qw( Bool Int Object Str );
use File::DataClass::IO    qw( io );
use Try::Tiny;
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms';
with    'HTML::Forms::Role::Defaults';

has '+do_form_wrapper'  => default => FALSE;
has '+info_message'     => default => 'Select file name';
has '+name'             => default => 'BugAttachment';
has '+no_update'        => default => TRUE;
has '+title'            => default => 'Attach File';

has 'bug' => is => 'ro', isa => Object, required => TRUE;

has 'destination' => is => 'rw', isa => Str, default => NUL;

has 'extensions' => is => 'ro', isa => Str, default => 'csv|txt';

has 'file' => is => 'ro', isa => Object, required => TRUE;

has 'is_editor' => is => 'ro', isa => Bool, default => FALSE;

has 'max_copies' => is => 'ro', isa => Int, default => 9;

has 'max_size' => is => 'ro', isa => Int, default => 0;

has '_icons' =>
   is      => 'lazy',
   isa     => Str,
   default => sub { shift->context->icons_uri->as_string };

has_field 'file' => type => 'Upload';

has_field 'submit' => type => 'Button', label => 'Attach';

after 'before_build_fields' => sub {
   my $self = shift;

   $self->add_form_element_class('filemanager');
   return;
};

sub validate {
   my $self = shift;

   return unless $self->validated;

   my $context = $self->context;
   my $request = $context->request;

   return $self->add_form_error('Request has no upload object')
      unless $request->has_upload;

   my $upload = $request->upload;

   return $self->add_form_error($upload->reason) unless $upload->is_upload;

   my $filename = $request->query_parameters->{name} || $upload->filename;

   $filename = $self->file->scrub($filename);

   my ($extn) = $filename =~ m{ \. ([^\.]+) \z }mx;

   return $self->add_form_error(
      'Size [_1] greater than maximum [_2]', $upload->size, $self->max_size
   ) if $self->max_size and $upload->size > $self->max_size;

   my $extns = $self->extensions;

   return $self->add_form_error('File type [_1] not allowed', ".${extn}")
      unless $extn =~ m{ \A (?: $extns ) \z }mx;

   my $bug_id    = $self->bug->id;
   my $directory = $context->get_body_parameters->{directory} // NUL;

   $directory = "${bug_id}!${directory}";

   my $base = $self->file->directory($directory);
   my $dest = $base->catfile($filename)->assert_filepath;

   if ($dest->exists) {
      $filename = $self->_next_filename($base, $filename);
      $dest     = $filename ? $base->catfile($filename) : NUL;
   }

   return unless $dest;

   try   { io($upload->path)->copy($dest) }
   catch { $self->add_form_error("${_}") };

   return if $self->result->has_form_errors;

   $self->file->add_meta($context->session->username, $directory, $filename);
   $self->destination($dest->basename);

   $context->model('BugAttachment')->create({
      bug_id  => $bug_id,
      path    => $filename,
      user_id => $context->session->id
   });

   return;
}

sub _next_filename {
   my ($self, $directory, $filename) = @_;

   my ($basename, $extn) = $filename =~ m{ \A (.+) \. ([^\.]+) \z }mx;

   for my $count (1 .. $self->max_copies) {
      $filename = "${basename}(${count}).${extn}";

      return $filename unless $directory->catfile($filename)->exists;
   }

   return;
}

use namespace::autoclean -except => META;

1;
