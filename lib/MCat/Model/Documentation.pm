package MCat::Model::Documentation;

use MCat::Constants qw( EXCEPTION_CLASS FALSE TRUE );
use MCat::Util      qw( redirect );
use MCat::File::Docs::View;
use Moo;
use MCat::Navigation::Attributes; # Will do cleaning

extends 'MCat::Model';
with    'Web::Components::Role';
with    'MCat::Role::FileMeta';

has '+moniker' => default => 'doc';

has '_doc_viewer' =>
   is      => 'ro',
   default => sub { MCat::File::Docs::View->new() };

sub base : Auth('view') {
   my ($self, $context) = @_;

   $context->stash('nav')->finalise;

   return;
}

sub config_edit : Auth('admin') Nav('Edit') {
   my ($self, $context) = @_;

   my $options = { context => $context };
   my $form    = $self->new_form('Configuration::Edit', $options);

   if ($form->process(posted => $context->posted)) {
      my $edit = $context->uri_for_action('doc/config_edit');
      my $args = ['File [_1] updated', $self->config->local_config_file];

      $context->stash(redirect $edit, $args);
   }

   $context->stash(form => $form);
   return;
}

sub configuration : Auth('admin') Nav('View') {
   my ($self, $context) = @_;

   my $options = { context => $context };

   $context->stash(form => $self->new_form('Configuration', $options));
   return;
}

sub frontend : Auth('view') Nav('Browser') {
   my ($self, $context) = @_;

   return;
}

sub list : Auth('view') Nav('Server') {
   my ($self, $context) = @_;

   my $options   = {
      context    => $context,
      file_home  => $self->file_home,
      file_share => $self->file_share,
   };
   my $params    = $context->request->query_parameters;
   my $directory = $params->{directory};
   my $selected  = $params->{selected};

   $options->{directory} = $directory if $directory;
   $options->{selected}  = $selected  if $selected;

   $context->stash(table => $self->new_table('Docs', $options));
   return;
}

sub view : Auth('view') Nav('View Docs') {
   my ($self, $context, $file) = @_;

   my $params    = $context->request->query_parameters;
   my $directory = $self->file->directory($params->{directory});
   my $markup    = $self->_doc_viewer->get($directory->catfile($file));

   $context->stash(documentation => $markup);
   return;
}

1;
