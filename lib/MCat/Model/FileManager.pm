package MCat::Model::FileManager;

use HTML::StateTable::Constants qw( EXCEPTION_CLASS FALSE ITERATOR_DOWNLOAD_KEY
                                    NUL TRUE );
use HTTP::Status                qw( HTTP_OK );
use MCat::Util                  qw( redirect );
use Unexpected::Functions       qw( Unspecified );
use Try::Tiny;
use Moo;
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

   my $options = { action => NUL, name => 'FileManager', operation => 'copy' };
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

   my $options = { action => NUL, name => 'FileManager', operation => 'mkpath'};
   my $message = sub { ['Folder [_1] created', shift->field('name')->value] };

   $self->_filemanager_form($context, $options, $message);
   return;
}

sub header {
   my ($self, $context, $selected) = @_;

   return $self->error($context, Unspecified, ['file']) unless $selected;

   my $header = $self->file->get_csv_header($selected);

   $context->stash(json => $header, code => HTTP_OK, view => 'json');
   return;
}

sub list : Nav('File Manager') {
   my ($self, $context) = @_;

   my $options   = {
      context    => $context,
      extensions => $self->file_extensions,
      file_home  => $self->file_home,
      file_share => $self->file_share,
   };
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

   my ($directory, $message, $selected);

   if (my $data = $context->get_body_parameters->{data}) {
      $directory = $self->file->to_path($data->{directory});
      $selected  = $data->{selected};
      $message   = $self->_move_selected($context, $directory, $selected);
   }
   else { $message = ['Nothing pasted'] }

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

   my ($count, $directory, $message);

   if (my $data = $context->get_body_parameters->{data}) {
      $directory = $self->file->to_path($data->{directory});
      ($count, $message) = $self->_remove_selected($context, $data->{selector});
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

   my $options = { action => NUL, name => 'FileManager', operation => 'move' };
   my $message = sub {
      my $form  = shift;
      my $value = $form->field('name')->value;

      return ['File [_1] renamed to [_2]', $form->selected_path, $value];
   };

   $self->_filemanager_form($context, $options, $message);
   return;
}

sub select {
   my ($self, $context) = @_;

   my $options    = { context => $context };
   my $params     = $context->request->query_parameters;
   my $directory  = $params->{directory};
   my $extensions = $params->{extensions};
   my $selected   = $params->{selected};

   $options->{configurable} = FALSE;
   $options->{caption}      = NUL;
   $options->{directory}    = $directory  if $directory;
   $options->{extensions}   = $extensions if $extensions;
   $options->{selected}     = $selected   if $selected;
   $options->{selectonly}   = TRUE;

   $context->stash(table => $self->new_table('FileManager', $options));
}

sub upload {
   my ($self, $context) = @_;

   my $options = {
      action     => NUL,
      extensions => $self->file_extensions,
      max_copies => 9,
      max_size   => $self->file_max_size,
      name       => 'FileUpload',
   };
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
      my $directory = $self->file->directory($params->{directory});
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
   my $directory = $self->file->to_path($params->{directory});

   $options->{context}    = $context;
   $options->{directory}  = $directory if $directory;
   $options->{file_home}  = $self->file_home;
   $options->{file_share} = $self->file_share;

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

sub _move_selected {
   my ($self, $context, $directory, $selected) = @_;

   $selected = $self->file->to_path($selected);

   my $from = $self->file->directory->child($selected);
   my $message;

   if ($from->exists) {
      my $pathname = $from->basename;
      my $basedir  = $self->file->directory($directory);
      my $to       = $basedir->catfile($pathname);
      my $meta     = { owner => $context->session->username };

      $self->file->unshare_file($from);
      $from->move($to);
      $self->file->move_meta($from, $directory, $pathname, $meta);
      $self->file->share_file($to)
         if $self->file->get_shared($directory, $pathname);

      $message = $to->is_file ? 'File [_1] pasted' : 'Folder [_1] pasted';
      $message = [$message, $pathname];
   }
   else { $message = ['Path [_1] not found', $from] }

   return $message;
}

sub _remove_selected {
   my ($self, $context, $selector) = @_;

   my $count = 0;
   my $message;

   for my $selected (map { $self->file->to_path($_) } @{$selector}) {
      my $path = $self->file->directory->child($selected);

      next unless $path->exists;

      try {
         $self->file->unshare_file($path);

         if ($path->is_file) { $path->unlink }
         else { $path->rmdir }

         $self->file->remove_meta($path);
         $count++;
      }
      catch { $message = ["${_}"] };
   }

   return $count, $message;
}

sub _stash_redirect {
   my ($self, $context, $directory, $message) = @_;

   my $params = $directory ? { directory => $directory } : {};
   my $list   = $context->uri_for_action('file/list', [], $params);

   $context->stash(redirect $list, $message);
   return;
}

1;
