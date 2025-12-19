package MCat::Form::Filter;

use HTML::Forms::Constants qw( FALSE META NUL TRUE USERID );
use HTML::Forms::Types     qw( HashRef Int );
use Scalar::Util           qw( blessed );
use Try::Tiny;
use Moo;
use MooX::HandlesVia;
use HTML::Forms::Moo;

extends 'HTML::Forms::Model::DBIC';
with    'HTML::Forms::Role::Defaults';
with    'MCat::Role::JSONParser';

has '+name'                => default => 'edit_filter';
has '+title'               => default => 'Filter';
has '+default_wrapper_tag' => default => 'fieldset';
has '+do_form_wrapper'     => default => TRUE;
has '+form_element_class'  => default => sub { ['wide'] };
has '+info_message'        => default => 'You know what to do';
has '+is_html5'            => default => TRUE;
has '+item_class'          => default => 'Filter';

has 'filter_config' =>
   is          => 'lazy',
   isa         => HashRef,
   handles_via => 'Hash',
   handles     => { has_filter_config => 'count' },
   default     => sub {
      my $self = shift;

      return {} unless $self->item;

      my $base = $self->context->request->uri_for(NUL);

      return {
         'api-uri'          => 'api/object/*/*',
         'icons'            => $self->context->icons_uri->as_string,
         'request-base'     => $base->as_string,
         'editor-min-width' => $self->editor_min_width,
         'selector-uri'     => 'filter/selector/*',
         'table-id'         => $self->item->table_id,
      };
   };

has 'editor_min_width' => is => 'ro', isa => Int, default => 250;

has_field 'name' => required => TRUE;

has_field 'description';

has_field 'core_table' =>
   type          => 'Select',
   label         => 'Table',
   default       => 1;

sub options_table {
   my $self     = shift;
   my $field    = $self->field('core_table');
   my $accessor = $field->parent->full_accessor if $field->parent;
   my $options  = $self->lookup_options($field, $accessor);

   return [ map { ucfirst } @{$options} ];
}

has_field 'owner' => type => 'Hidden';

sub default_owner {
   my $self    = shift;
   my $context = $self->context;

   return $context && $context->can('session')
      ? $context->session->id : USERID;
}

has_field 'filter_json' => type => 'Hidden', default => NUL;

has_field 'filter_editor' =>
   type     => 'NoValue',
   do_label => FALSE,
   html     => NUL,
   wrapper_class => ['input-filter'];

has_field 'view' =>
   type          => 'Link',
   label         => 'View',
   element_class => ['form-button pageload'],
   wrapper_class => ['input-button', 'inline'];

has_field 'submit' => type => 'Button';

after 'after_build_fields' => sub {
   my $self    = shift;
   my $context = $self->context;

   $self->field('core_table')->disabled(TRUE) if $self->item;

   if ($self->has_filter_config) {
      $self->field('name')->add_wrapper_class('inline collapse');
      $self->field('description')->add_wrapper_class('inline collapse');
      $self->field('core_table')->add_wrapper_class('inline collapse');

      my $config = $self->json_parser->encode($self->filter_config);
      my $html   = $self->renderer->html->div({
         'id' => 'filter-container',
         'class' => 'filter-container',
         'data-filter-config' => $config
      });

      $self->field('filter_editor')->html($html);
   }

   if ($self->item) {
      my $view = $context->uri_for_action('filter/view', [$self->item->id]);

      $self->field('view')->href($view->as_string);
      $self->field('submit')->add_wrapper_class(['inline', 'right']);
   }
   else { $self->field('view')->inactive(TRUE) }

   return;
};

sub validate {
   my $self = shift;

   return unless $self->validated;

   my $field = $self->field('filter_json');

   try { $self->item->parse($field->value) }
   catch {
      $self->add_form_error(blessed $_ ? $_->original : "${_}");
      $self->log->alert($_, $self->context) if $self->has_log;
   };

   return;
}

use namespace::autoclean -except => META;

1;
