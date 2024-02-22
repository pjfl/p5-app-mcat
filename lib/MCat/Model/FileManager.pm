package MCat::Model::FileManager;

use HTML::StateTable::Constants qw( FALSE ITERATOR_DOWNLOAD_KEY NUL TRUE );
use MCat::Util                  qw( redirect );
use Try::Tiny;
use Web::Simple;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';
with    'MCat::Role::FileMeta';

has '+moniker' => default => 'file';

sub base {
   my ($self, $context) = @_;

   $context->stash('nav')->list('filemanager')->finalise;

   return;
}

sub copy {
   my ($self, $context) = @_;

   my $options = {
      action    => NUL,
      name      => 'FileManager',
      operation => 'copy',
      title     => 'Copy File'
   };
   my $message = sub {
      my $form  = shift;
      my $value = $form->field('name')->value;

      return ['File [_1] copied to [_2]', $form->selected_path, $value];
   };

   $self->_filemanager_form($context, $options, $message);
   return;
}

sub create {
   my ($self, $context) = @_;

   my $options = {
      action    => NUL,
      name      => 'FileManager',
      operation => 'mkpath',
      title     => 'New Folder'
   };
   my $message = sub { ['Folder [_1] created', shift->field('name')->value] };

   $self->_filemanager_form($context, $options, $message);
   return;
}

sub list : Nav('File Manager') {
   my ($self, $context) = @_;

   my $options   = { context => $context };
   my $params    = $context->request->query_parameters;
   my $directory = $params->{directory};
   my $selected  = $params->{selected};

   $options->{directory} = $directory if $directory;
   $options->{selected}  = $selected  if $selected;

   $context->stash(table => $self->new_table('FileManager', $options));
   return;
}

sub paste {
   my ($self, $context) = @_;

   return unless $self->verify_form_post($context);

   my $message = ['Nothing pasted'];
   my $directory;

   if (my $data = $context->get_body_parameters->{data}) {
      my $selected = $self->meta_to_path($data->{selected});
      my $from     = $self->meta_directory($context)->child($selected);

      if ($from->exists) {
         my $pathname = $from->basename;
         my $basedir  = $self->meta_directory($context, $directory);
         my $to       = $basedir->catfile($pathname);

         $from->move($to);
         $self->meta_move($context, $directory, $from, $pathname);
         $message = $to->is_file ? 'File [_1] pasted' : 'Folder [_1] pasted';
         $message = [$message, $pathname];
      }
      else { $message = ['Path [_1] not found', $from] }

      $directory = $self->meta_to_path($data->{directory});
   }

   $self->_stash_redirect($context, $directory, $message);
   return;
}

sub properties {
   my ($self, $context) = @_;

   my $options   = { name => 'FileProperties' };
   my $params    = $context->request->query_parameters;
   my $directory = $params->{directory};
   my $selected  = $params->{selected};

   $options->{directory} = $directory if $directory;
   $options->{selected}  = $selected  if $selected;

   my $message  = sub {
      my $form     = shift;
      my $template = ($form->type eq 'file' ? 'File' : 'Folder')
         . ' [_1] properties updated';

      return [$template, $form->selected]
   };

   $self->_filemanager_form($context, $options, $message);
   return;
}

sub remove {
   my ($self, $context) = @_;

   return unless $self->verify_form_post($context);

   my $count = 0;
   my ($directory, $message);

   if (my $data = $context->get_body_parameters->{data}) {
      for my $selected (map { $self->meta_to_path($_) } @{$data->{selector}}) {
         my $path = $self->meta_directory($context)->child($selected);

         next unless $path->exists;

         try {
            $self->meta_unshare($context, $path);

            if ($path->is_file) { $path->unlink }
            else { $path->rmdir }

            $self->meta_remove($path);
            $count++;
         }
         catch { $message = ["${_}"] };
      }

      $directory = $self->meta_to_path($data->{directory});
   }

   unless ($message) {
      $message = ['Nothing deleted'];

      if ($count == 1) { $message = ['One file/folder deleted'] }
      elsif ($count > 1) { $message = ['[_1] files/folders deleted', $count] }
   }

   $self->_stash_redirect($context, $directory, $message);
   return;
}

sub rename {
   my ($self, $context) = @_;

   my $options = {
      action    => NUL,
      name      => 'FileManager',
      operation => 'move',
      title     => 'Rename File'
   };
   my $message = sub {
      my $form  = shift;
      my $value = $form->field('name')->value;

      return ['File [_1] renamed to [_2]', $form->selected_path, $value];
   };

   $self->_filemanager_form($context, $options, $message);
   return;
}

sub upload {
   my ($self, $context) = @_;

   my $options = { action => NUL, max_copies => 9, name => 'FileUpload' };
   my $owner   = $context->session->username;
   my $message = sub {
      my $form = shift;

      return ['File [_1] uploaded by [_2]', $form->destination, $owner]
         if $form->destination;

      return ['No more copies allowed'];
   };

   $self->_filemanager_form($context, $options, $message);
   return;
}

sub view {
   my ($self, $context, $filename) = @_;

   my $params = $context->request->query_parameters;

   if ($params->{download}) {
      my $directory = $self->meta_directory($context, $params->{directory});
      my $object    = $directory->catfile($filename)->slurp;
      my $key       = ITERATOR_DOWNLOAD_KEY();

      $context->stash(
         $key => { filename => $filename, object => $object },
         view => 'table',
      );
      return;
   }

   my $options = { filename => $filename, name => 'FileView' };

   $self->_filemanager_form($context, $options, sub {});
   return;
}

# Private methods
sub _filemanager_form {
   my ($self, $context, $options, $message) = @_;

   my $params    = $context->request->query_parameters;
   my $directory = $self->meta_to_path($params->{directory});

   $options->{context}   = $context;
   $options->{directory} = $directory if $directory;

   my $form = $self->new_form($options->{name}, $options);

   if ($form->process(posted => $context->posted)) {
      $self->_stash_redirect($context, $directory, $message->($form));
      return;
   }

   if ($context->posted) {
      $self->_stash_redirect($context, $directory, $form->form_errors);
      return;
   }

   $context->stash(form => $form);
   return;
}

sub _stash_redirect {
   my ($self, $context, $directory, $message) = @_;

   my $params = $directory ? { directory => $directory } : {};
   my $list   = $context->uri_for_action('file/list', [], $params);

   $context->stash(redirect $list, $message);
   return;
}

1;
