package MCat::Form::Filter::Editor;

use HTML::Forms::Constants qw( FALSE META NUL TRUE USERID );
use HTML::Forms::Types     qw( Int );
use Scalar::Util           qw( blessed );
use Try::Tiny;
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Model::DBIC';
with    'HTML::Forms::Role::Defaults';

has '+name'         => default => 'filter_editor';
has '+title'        => default => 'Filter Editor';
has '+info_message' => default => 'You know what to do';
has '+item_class'   => default => 'Filter';

has_field 'name' => type => 'Display';

has_field 'description' => type => 'Hidden';

has_field 'owner' => type => 'Hidden';

has_field 'core_table' => type => 'Hidden';

has_field 'filter_json' => type => 'Hidden';

has_field 'submit' => type => 'Button';

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
