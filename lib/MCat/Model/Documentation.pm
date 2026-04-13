package MCat::Model::Documentation;

use MCat::Constants        qw( EXCEPTION_CLASS FALSE TRUE );
use File::DataClass::Types qw( Path );
use File::DataClass::IO    qw( io );
use MCat::Util             qw( redirect );
use MCat::File::Docs::View;
use Moo;
use MCat::Navigation::Attributes; # Will do cleaning

extends 'MCat::Model';
with    'Web::Components::Role';
with    'MCat::Role::FileMeta';

has '+moniker' => default => 'doc';

has 'local_library' =>
   is      => 'ro',
   isa     => Path,
   default => sub { io((split m{ : }mx, $ENV{PERL5LIB})[1]) };

has '_doc_viewer' =>
   is      => 'ro',
   default => sub { MCat::File::Docs::View->new() };

sub base : Auth('view') {
   my ($self, $context) = @_;

   $context->stash('nav')->finalise;

   return;
}

sub api : Auth('view') Nav('API') {
   my ($self, $context) = @_;

   my $api    = $context->controllers->{rest}->api;
   my $prefix = $context->request->uri_for($api->route_prefix);
   my $name   = $context->request->query_parameters->{entity};

   $context->stash(entity_list  => $api->entity_list);
   $context->stash(entity       => $api->get_entity($name));
   $context->stash(route_prefix => $prefix);
   return;
}

sub application : Auth('view') Nav('Application') {
   my ($self, $context) = @_;

   my $options   = {
      caption    => 'Application Documentation',
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

   my $file = $params->{file};

   $file = 'MCat.pm' unless $directory;

   return unless $file;

   $directory = $self->file->directory($directory);

   my $markup = $self->_doc_viewer->get($directory->catfile($file));

   $context->stash(documentation => $markup);
   return;
}

sub client : Auth('view') Nav('Client') {
   my ($self, $context) = @_;

   return;
}

sub configuration : Auth('admin') Nav('View') {
   my ($self, $context) = @_;

   my $form = $self->new_form('Configuration', { context => $context });

   $context->stash(form => $form);
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

sub server : Auth('view') Nav('Server') {
   my ($self, $context) = @_;

   my $locallib = $self->local_library;
   my $params   = $context->request->query_parameters;
   my $options  = {
      action      => 'doc/server',
      action_view => 'doc/server',
      caption     => 'Server Documentation',
      context     => $context,
      file_home   => $locallib,
      file_share  => $self->file_share,
   };
   my $directory = $params->{directory};
   my $selected  = $params->{selected};

   $options->{directory} = $directory if $directory;
   $options->{selected}  = $selected  if $selected;

   $context->stash(table => $self->new_table('Docs', $options));

   my $file = $params->{file};

   return unless $file;

   $directory = $locallib->catdir($self->file->to_path($params->{directory}));

   my $markup = $self->_doc_viewer->get($directory->catfile($file));

   $context->stash(documentation => $markup);
   return;
}

1;
