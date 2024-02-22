package MCat::Table::FileManager;

use HTML::StateTable::Constants qw( FALSE NUL SPC TABLE_META TRUE );
use File::DataClass::Types      qw( Directory Str );
use Format::Human::Bytes;
use HTML::StateTable::ResultSet::File::List;
use Moo;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';
with    'HTML::StateTable::Role::Configurable';
with    'HTML::StateTable::Role::Form';
with    'HTML::StateTable::Role::HighlightRow';
with    'HTML::StateTable::Role::Reorderable';
with    'HTML::StateTable::Role::Tag';
with    'MCat::Role::FileMeta';

has '+caption' => default => 'File Manager';

has '+configurable_action' => default => 'api/table_preference';

has '+configurable_dialog_close' => default => sub {
   return shift->context->request->uri_for('img/cancel.svg')->as_string;
};

has '+configurable_label' => default => sub {
   return shift->context->request->uri_for('img/tune.svg')->as_string;
};

has '+form_buttons' => default => sub { shift->_build_form_buttons };

has '+form_control_location' =>
   default => sub { [qw(TopLeft BottomLeft BottomRight)] };

has '+paging' => default => FALSE;

has '+tag_breadcrumbs' => default => TRUE;

has '+tag_control_location' => default => 'Title';

has '+tag_direction' => default => 'right';

has '+tag_names' => default => sub { shift->_build_tag_names };

has '+title_location' => default => 'outer';

has '_directory' => is => 'ro', isa => Str, init_arg => 'directory';

has 'directory' => is => 'lazy', isa => Directory, init_arg => undef;

has 'format_number' => is => 'ro', default => sub { Format::Human::Bytes->new };

has 'selected' => is => 'ro', isa => Str, predicate => 'has_selected';

setup_resultset sub {
   my $self = shift;

   return HTML::StateTable::ResultSet::File::List->new(
      allow_directories => TRUE,
      directory         => $self->directory,
      extension         => NUL,
      recurse           => FALSE,
      result_class      => 'MCat::Logfile::Result::List', # TODO: Fix name
      table             => $self
   );
};

set_table_name 'filemanager';

has_column 'icon' => cell_traits => ['Icon'], label => 'Type';

has_column 'name' =>
   cell_traits => ['Modal'],
   link        => sub {
      my $cell = shift; return $cell->table->_build_name_link($cell);
   },
   options  => { 'trigger-modal' => 'modal' },
   sortable => TRUE;

has_column 'owner' =>
   value => sub {
      my $cell  = shift;
      my $table = $cell->table;

      return $table->meta_get_owner(
         $table->context, $table->_directory, $cell->result->name
      );
   };

has_column 'shared' =>
   cell_traits => ['Bool'],
   value       => sub {
      my $cell   = shift;
      my $table  = $cell->table;
      my $shared = $table->meta_get_shared(
         $table->context, $table->_directory, $cell->result->name
      );

      return $cell->result->type eq 'file' ? ($shared ? TRUE : FALSE) : NUL;
   };

has_column 'size' =>
   cell_traits => ['Numeric'],
   value       => sub {
      my $cell = shift;

      return $cell->table->format_number->base2($cell->result->size);
   };

has_column 'modified' => cell_traits => ['DateTime'], sortable => TRUE;

has_column 'check' =>
   cell_traits => ['Checkbox'],
   label       => 'Select',
   value       => sub {
      my $cell = shift;

      return $cell->table->_qualified_directory($cell->result);
   };

sub highlight_row {
   my ($self, $row) = @_;

   return FALSE unless $self->selected;

   return $self->selected eq $row->result->name ? TRUE : FALSE;
}

# Private methods
sub _build_directory {
   my $self = shift;

   return $self->meta_directory($self->context, $self->_directory);
}

sub _build_form_buttons {
   my $self    = shift;
   my $context = $self->context;
   my $params  = {};

   $params->{directory} = $self->_directory if $self->_directory;
   $params->{selected}  = $self->selected   if $self->has_selected;

   my $cut_or_paste;

   if ($self->has_selected) {
      $cut_or_paste = {
         action    => 'file/paste',
         noconfirm => TRUE,
         selection => 'disable_on_select',
         value     => 'Paste'
      };
   }
   else {
      $cut_or_paste = {
         action    => $context->uri_for_action('file/list', [], $params),
         method    => 'get',
         noconfirm => TRUE,
         selection => 'select_one',
         value     => 'Cut'
      };
   }

   return {
      'TopLeft' => [{
         action    => $context->uri_for_action('file/create', [], $params),
         display   => 'modal',
         field     => 'name',
         formclass => 'filemanager',
         method    => 'get',
         selection => 'disable_on_select',
         value     => 'New Folder'
      }, {
         action    => $context->uri_for_action('file/upload', [], $params),
         display   => 'modal',
         field     => 'file',
         formclass => 'filemanager',
         method    => 'get',
         selection => 'disable_on_select',
         value     => 'Upload'
      }],
      'BottomLeft' => [{
         action    => $context->uri_for_action('file/properties', [], $params),
         display   => 'modal',
         formclass => 'filemanager',
         method    => 'get',
         noButtons => TRUE,
         selection => 'select_one',
         value     => 'Properties'
      },{
         action    => $context->uri_for_action('file/copy', [], $params),
         display   => 'modal',
         field     => 'name',
         formclass => 'filemanager',
         method    => 'get',
         selection => 'select_one',
         value     => 'Copy'
      },
      $cut_or_paste,
      {
         action    => $context->uri_for_action('file/rename', [], $params),
         display   => 'modal',
         field     => 'name',
         formclass => 'filemanager',
         method    => 'get',
         selection => 'select_one',
         value     => 'Rename'
      }],
      'BottomRight' => [{
         action    => 'file/remove',
         selection => 'selection',
         value     => 'Delete',
      }]
   };
}

sub _build_name_link {
   my ($self, $cell) = @_;

   my $result = $cell->result;
   my $params = {};

   if ($result->type eq 'directory') {
      my $selected = $self->context->request->query_parameters->{selected};

      $params->{directory} = $self->_qualified_directory($result);
      $params->{selected}  = $selected if $selected;

      return $self->context->uri_for_action('file/list', [], $params);
   }
   elsif ($result->type eq 'file') {
      my $args = [$result->uri_arg];
      my $dir  = $self->_qualified_directory;

      $params->{directory} = $dir if $dir;
      $params->{modal} = 'true';

      return $self->context->uri_for_action('file/view', $args, $params);
   }

   return;
}

sub _build_tag_names {
   my $self  = shift;
   my $names = ['Home'];

   push @{$names}, split m{ / }mx, $self->meta_to_path($self->_directory)
      if $self->_directory;

   my $tuples = [];
   my $directory = NUL;

   for my $name (@{$names}) {
      my $params = {};

      unless ($name eq 'Home') {
         $directory = $self->meta_to_uri($directory, $name);
         $params = { directory => $directory };
      }

      $params->{selected} = $self->selected if $self->has_selected;

      my $uri = $self->context->uri_for_action('file/list', [], $params);

      push @{$tuples}, [$name, $uri];
   }

   return $tuples;
}

sub _qualified_directory {
   my ($self, $result) = @_;

   return $self->meta_to_uri($self->_directory) unless $result;

   return $self->meta_to_uri($self->_directory, $result->uri_arg);
}

use namespace::autoclean -except => TABLE_META;

1;
