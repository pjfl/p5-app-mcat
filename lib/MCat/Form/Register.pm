package MCat::Form::Register;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE META TRUE );
use JSON::MaybeXS          qw( encode_json );
use MCat::Util             qw( create_token redirect );
use Type::Utils            qw( class_type );
use Unexpected::Functions  qw( catch_class );
use Try::Tiny;
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms';
with    'HTML::Forms::Role::Defaults';

has '+default_wrapper_tag' => default => 'fieldset';
has '+do_form_wrapper' => default => TRUE;
has '+info_message' => default => 'Answer the registration questions';
has '+is_html5' => default => TRUE;
has '+item_class' => default => 'User';
has '+no_update' => default => TRUE;
has '+title' => default => 'Registration Request';

has 'redis' => is => 'ro', isa => class_type('MCat::Redis'), required => TRUE;

has_field 'name' => label => 'User Name', required => TRUE;

has_field 'email' => type => 'Email', required => TRUE;

has_field 'submit' => type => 'Submit';

sub validate {
   my $self  = shift;
   my $rs    = $self->context->model($self->item_class);
   my $name  = $self->field('name');
   my $email = $self->field('email');

   $name->add_error('User name [_1] not unique', [$name->value])
      if $rs->find({ name  => $name->value });
   $email->add_error('Email address [_1] not unique', [$email->value])
      if $rs->find({ email => $email->value });

   return if $self->result->has_errors;

   try {
      $self->context->stash( job => $self->_create_email($name, $email) );
   }
   catch_class [
      '*' => sub {
         $self->add_form_error($_);
         $self->log->alert($_, $self->context) if $self->has_log;
      }
   ];

   return;
}

sub _create_email {
   my ($self, $name, $email) = @_;

   my $token   = create_token;
   my $context = $self->context;
   my $link    = $context->uri_for_action('page/register', [$token]);
   my $passwd  = substr create_token, 0, 12;
   my $options = {
      application => $context->config->name,
      email       => $email->value,
      link        => "${link}",
      password    => $passwd,
      recipients  => [$email->value],
      subject     => 'User Registration',
      template    => 'register_user.md',
      username    => $name->value,
   };

   $self->redis->set($token, encode_json($options));

   my $program = $context->config->bin->catfile('mcat-cli');
   my $command = "${program} -o token=${token} send_message email";

   $options = { command => $command, name => 'send_message' };

   return $context->model('Job')->create($options);
}

use namespace::autoclean -except => META;

1;
