package MCat::Form::ListUpdate;

use HTML::Forms::Constants qw( FALSE META TRUE );
use Try::Tiny;
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Model::DBIC';
with    'HTML::Forms::Role::Defaults';

has '+title'                 => default => 'List Update';
has '+default_wrapper_tag'   => default => 'fieldset';
has '+do_form_wrapper'       => default => TRUE;
has '+info_message'          => default =>
   'Select a filter and create the update job';
has '+messages_before_start' => default => FALSE;
has '+no_update'             => default => TRUE;

has_field 'name' => type => 'Display';

has_field 'filter' => type => 'Select', label => 'Filter', required => TRUE;

sub options_filter {
   my $self    = shift;
   my $where   = { table_id => $self->item->table_id };
   my $filters = [ $self->context->model('Filter')->search($where)->all ];

   return [ map { { label => $_->name, value => $_->id } } @{$filters} ];
}

has_field 'submit' => type => 'Submit';

sub validate {
   my $self      = shift;
   my $filter_id = $self->field('filter')->value;

   try   { $self->_update_list($self->item->id, $filter_id) }
   catch { $self->add_form_error("${_}") };

   return;
}

sub _update_list {
   my ($self, $list_id, $filter_id) = @_;

   my $program = $self->context->config->bin->catfile('mcat-cli');
   my $options = "-o list_id=${list_id} -o filter_id=${filter_id}";
   my $command = "${program} ${options} update_list";
   my $args    = { command => $command, name => 'update_list' };

   return $self->context->model('Job')->create($args);
}

use namespace::autoclean -except => META;

1;
