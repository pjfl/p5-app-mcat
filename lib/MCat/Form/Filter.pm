package MCat::Form::Filter;

use HTML::Forms::Constants qw( FALSE META NUL TRUE USERID );
use HTML::Forms::Types     qw( Int );
use Scalar::Util           qw( blessed );
use Try::Tiny;
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Model::DBIC';
with    'HTML::Forms::Role::Defaults';

has '+name'                => default => 'edit_filter';
has '+title'               => default => 'Filter';
has '+default_wrapper_tag' => default => 'fieldset';
has '+do_form_wrapper'     => default => TRUE;
has '+info_message'        => default => 'You know what to do';
has '+is_html5'            => default => TRUE;
has '+item_class'          => default => 'Filter';

has_field 'name' => required => TRUE;

has_field 'description';

has_field 'owner' => type => 'Hidden';

sub default_owner {
   my $self    = shift;
   my $context = $self->context;

   return $context && $context->can('session')
      ? $context->session->id : USERID;
}

has_field 'core_table' => type => 'Select', label => 'Table', default => 1;

sub options_table {
   my $self     = shift;
   my $field    = $self->field('core_table');
   my $accessor = $field->parent->full_accessor if $field->parent;
   my $options  = $self->lookup_options($field, $accessor);

   return [ map { ucfirst } @{$options} ];
}

has_field 'filter_json' => type => 'Hidden', default => NUL;

has_field 'submit' => type => 'Button';

after 'after_build_fields' => sub {
   my $self = shift;

   $self->field('core_table')->disabled(TRUE) if $self->item;
   return;
};

sub validate {
   my $self = shift;

   return if $self->result->has_errors;

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
