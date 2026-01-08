package MCat::Form::User;

use HTML::Forms::Constants qw( FALSE META TRUE );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms::Model::DBIC';
with    'HTML::Forms::Role::Defaults';

has '+info_message' => default => 'With great power comes great responsibilty';
has '+item_class'   => default => 'User';
has '+title'        => default => 'User';

has 'config' => is => 'lazy', default => sub { shift->context->config };

has 'resultset' =>
   is      => 'lazy',
   default => sub {
      my $self = shift;

      return $self->context->model($self->item_class);
   };

has_field 'name', required => TRUE;

sub validate_name {
   my $self = shift;
   my $name = $self->field('name');

   $name->add_error("User name '[_1]' too short", $name->value)
      if length $name->value < $self->config->user->{min_name_len};

   $name->add_error("User name '[_1]' not unique", $name->value)
      if $self->resultset->find({ user_name => $name->value });

   return;
}

has_field 'email' => type => 'Email', required => TRUE;

sub validate_email {
   my $self  = shift;
   my $email = $self->field('email');

   $email->add_error("Email address '[_1]' not unique", $email->value)
      if $self->resultset->find({ email => $email->value });

   return;
}

has_field 'role' => type => 'Select', default => 2;

sub options_role {
   my $self  = shift;
   my $field = $self->field('role');

   my $accessor; $accessor = $field->parent->full_accessor if $field->parent;

   my $options = $self->lookup_options($field, $accessor);

   return [ map { ucfirst } @{$options} ];
}

has_field 'active' => type => 'Boolean', default => TRUE;

has_field 'password';

sub default_password {
   my $self   = shift;
   my $config = $self->context->config;
   my $user   = $self->context->model($self->item_class)->new_result({});

   return $user->encrypt_password($config->user->{default_password});
}

has_field 'password_expired' => type => 'Boolean', default => TRUE;

has_field 'submit' => type => 'Button';

has_field 'view' =>
   type          => 'Link',
   label         => 'View',
   element_class => ['form-button pageload'],
   wrapper_class => ['input-button', 'inline'];

after 'after_build_fields' => sub {
   my $self    = shift;
   my $context = $self->context;

   if ($self->item) {
      my $view = $context->uri_for_action('user/view', [$self->item->id]);

      $self->field('view')->href($view->as_string);
      $self->field('submit')->add_wrapper_class(['inline', 'right']);
   }
   else { $self->field('view')->inactive(TRUE) }

   return;
};

use namespace::autoclean -except => META;

1;
