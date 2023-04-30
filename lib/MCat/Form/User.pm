package MCat::Form::User;

use HTML::Forms::Constants qw( FALSE META TRUE );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Model::DBIC';
with    'HTML::Forms::Role::Defaults';

has '+title'               => default => 'User';
has '+default_wrapper_tag' => default => 'fieldset';
has '+do_form_wrapper'     => default => TRUE;
has '+info_message'        =>
   default => 'With great power comes great responsibilty';
has '+is_html5'            => default => TRUE;
has '+item_class'          => default => 'User';
has '+do_label_right'      => default => FALSE;
has '+do_label_colon'      => default => FALSE;

has_field 'name', required => TRUE;

has_field 'active' => type => 'Boolean', default => TRUE;

has_field 'password';

sub default_password {
   my $self = shift;
   my $user = $self->context->model($self->item_class)->new_result({});

   return $user->encrypt_password($self->context->config->default_password);
}

has_field 'password_expired' => type => 'Boolean', default => TRUE;

has_field 'role' => type => 'Select';

sub options_role {
   my $self     = shift;
   my $field    = $self->field('role');
   my $accessor = $field->parent->full_accessor if $field->parent;
   my $options  = $self->lookup_options($field, $accessor);

   return [ map { ucfirst } @{$options} ];
}

has_field 'submit' => type => 'Submit';

use namespace::autoclean -except => META;

1;
