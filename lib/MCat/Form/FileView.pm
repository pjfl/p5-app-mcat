package MCat::Form::FileView;

use HTML::Forms::Constants qw( FALSE META NUL TRUE );
use HTML::Forms::Types     qw( Maybe Str );
use Type::Utils            qw( class_type );
use MCat::Markdown;
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms';
with    'HTML::Forms::Role::Defaults';
with    'MCat::Role::FileMeta';

has '+do_form_wrapper' => default => FALSE;
has '+name'         => default => 'FileView';
has '+info_message' => default => NUL;
has '+no_update'    => default => TRUE;
has '+title'        => default => 'File Preview';

has 'directory' => is => 'ro', isa => Maybe[Str];

has 'filename' => is => 'ro', isa => Str, required => TRUE;

has 'formatter' =>
   is      => 'lazy',
   isa     => class_type('MCat::Markdown'),
   default => sub { MCat::Markdown->new( tab_width => 3 ) };

has_field 'preview' =>
   type          => 'NonEditable',
   wrapper_class => ['file-preview'];

has_field 'cancel' =>
   html_name     => 'submit',
   label         => 'Cancel',
   type          => 'Button',
   value         => 'cancel',
   wrapper_class => ['inline input-button left'];

has_field 'download' =>
   html_name     => 'submit',
   label         => 'Download',
   type          => 'Button',
   value         => 'download',
   wrapper_class => ['inline input-button right'];

after 'after_build_fields' => sub {
   my $self      = shift;
   my $context   = $self->context;
   my $directory = $self->meta_directory($context, $self->directory);
   my $file      = $directory->catfile($self->filename);
   my $content   = join "\n", map { "    ${_}" } $file->head(10);

   $self->field('preview')->html($self->formatter->markdown($content));

   my $args   = [$self->filename];
   my $params = { directory => $self->directory };
   my $js     = sprintf "%s(); %s('%s', '%s'); %s('%s'); %s()",
      'event.preventDefault',
      'HStateTable.Role.Downloadable.downloader',
      $context->uri_for_action(
         'file/view', $args, { %{$params}, download => 'true' }
      ),
      $self->filename,
      'MCat.Navigation.manager.renderLocation',
      $context->uri_for_action('file/list', [], $params),
      "HStateTable.Renderer.manager.tables['filemanager'].modal.close";

   $self->field('download')->element_attr->{javascript} = qq{onclick="${js}"};

   $js = sprintf "%s(); %s()",
      'event.preventDefault',
      "HStateTable.Renderer.manager.tables['filemanager'].modal.close";

   $self->field('cancel')->element_attr->{javascript} = qq{onclick="${js}"};
   return;
};

use namespace::autoclean -except => META;

1;
