package MCat::Form::Register;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE META TRUE );
use MCat::Util             qw( create_token redirect );
use Unexpected::Functions  qw( catch_class );
use Try::Tiny;
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms';
with    'HTML::Forms::Role::Defaults';

has '+form_wrapper_class' => default => sub { ['narrow'] };
has '+name'               => default => 'Register';
has '+title'              => default => 'Registration Request';
has '+info_message'       => default => 'Answer the registration questions';
has '+item_class'         => default => 'User';

has 'config' => is => 'lazy', default => sub { shift->context->config };

has 'resultset' =>
   is      => 'lazy',
   default => sub {
      my $self = shift;

      return $self->context->model($self->item_class);
   };

with 'MCat::Role::JSONParser';
with 'MCat::Role::Redis';

has_field 'name' =>
   label               => 'User Name',
   required            => TRUE,
   validate_inline     => TRUE,
   validate_when_empty => TRUE;

sub validate_name {
   my $self = shift;
   my $name = $self->field('name');

   $name->add_error("User name '[_1]' too short", $name->value)
      if length $name->value < $self->config->user->{min_name_len};

   $name->add_error("User name '[_1]' not unique", $name->value)
      if $self->resultset->find({ name => $name->value });

   return;
}

has_field 'email' =>
   type                => 'Email',
   required            => TRUE,
   validate_inline     => TRUE,
   validate_when_empty => TRUE;

sub validate_email {
   my $self  = shift;
   my $email = $self->field('email');

   $email->add_error("Email address '[_1]' not unique", $email->value)
      if $self->resultset->find({ email => $email->value });

   return;
}

has_field 'submit' => type => 'Button';

after 'after_build_fields' => sub {
   my $self = shift;
   my $attr = $self->field('name')->element_attr;

   $attr->{minlength} = $self->config->user->{min_name_len};
   return;
};

sub update_model {
   my $self  = shift;
   my $name  = $self->field('name');
   my $email = $self->field('email');

   try { $self->context->stash(job => $self->_create_email($name, $email)) }
   catch_class [
      '*' => sub {
         $self->add_form_error($_);
         $self->log->alert("${_}", $self->context) if $self->has_log;
      }
   ];

   return;
}

# Private methods
sub _create_email {
   my ($self, $name, $email) = @_;

   my $token   = create_token;
   my $link    = $self->context->uri_for_action('misc/register', [$token]);
   my $passwd  = substr create_token, 0, 12;
   my $options = {
      application => $self->config->name,
      email       => $email->value,
      link        => "${link}",
      password    => $passwd,
      recipients  => [$email->value],
      subject     => 'User Registration',
      template    => 'register_user.md',
      username    => $name->value,
   };

   $self->redis_client->set($token, $self->json_parser->encode($options));

   my $prefix  = $self->config->prefix;
   my $program = $self->config->bin->catfile("${prefix}-cli");
   my $command = "${program} -o token=${token} send_message email";

   $options = { command => $command, name => 'send_message' };

   return $self->context->model('Job')->create($options);
}

use namespace::autoclean -except => META;

1;
