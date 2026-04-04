package MCat::Form::Register;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE META TRUE );
use MCat::Util             qw( create_token redirect );
use Unexpected::Functions  qw( catch_class );
use Try::Tiny;
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms';
with    'HTML::Forms::Role::Defaults';
with    'MCat::Role::SendMessage';
with    'MCat::Role::JSONParser';
with    'HTML::Forms::Role::Captcha';

has '+info_message' => default => 'Answer the sign up questions';
has '+item_class'   => default => 'User';
has '+name'         => default => 'Register';
has '+title'        => default => 'Sign Up';

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
   label           => 'User Name',
   required        => TRUE,
   validate_inline => TRUE;

sub validate_name {
   my $self  = shift;
   my $name  = $self->field('name');
   my $value = $name->value;

   $name->add_error("User name '[_1]' too short", $value || '<empty>')
      if length $value < $self->config->user->{min_name_len};

   $name->add_error("User name '[_1]' not unique", $value || '<empty>')
      if $self->resultset->find({ name => $value });

   return;
}

has_field 'email' =>
   type            => 'Email',
   required        => TRUE,
   validate_inline => TRUE;

sub validate_email {
   my $self  = shift;
   my $email = $self->field('email');

   $email->add_error("Email address '[_1]' not unique", $email->value)
      if $self->resultset->find({ email => $email->value });

   return;
}

has_field 'captcha' => type => 'Captcha', label => 'Sentient?';

has_field 'submit' => type => 'Button';

after 'after_build_fields' => sub {
   my $self    = shift;
   my $name    = $self->field('name');
   my $context = $self->context;
   my $session = $context->session;

   $name->element_attr->{minlength} = $self->config->user->{min_name_len};

   $self->add_form_wrapper_class('narrow');
   $self->add_form_element_class('droplets') if $context->feature('droplets');
   $self->add_form_element_class('radar') if $context->feature('radar');

   my $captcha = $self->config->captcha;

   if ($captcha->{type} eq 'local') {
      my $uniq = substr create_token, 0, 8;
      my $url  = $context->uri_for_action($captcha->{image_action}, [$uniq]);

      $self->captcha_image_url($url);
   }
   elsif ($captcha->{type} eq 'remote') {
      my $field = $self->field('captcha');

      $field->captcha_type('remote');
      $field->site_key($captcha->{site_key});
      $field->secret_key($captcha->{secret_key});
      $field->theme($session->theme);
   }
   else { $self->field('captcha')->inactive(TRUE) }

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

   my $token     = create_token;
   my $config    = $self->config;
   my $context   = $self->context;
   my $passwd    = substr create_token, 0, 12;
   my $action    = $config->default_actions->{register};
   my $link      = $context->uri_for_action($action, [$token]);
   my $role_name = $config->user->{default_role} // 'view';
   my $role      = $context->model('Role')->find({ name => $role_name });
   my $params    = {
      application => $config->name,
      email       => $email->value,
      link        => "${link}",
      password    => $passwd,
      recipients  => [$email->value],
      role_id     => $role->id,
      subject     => 'User Registration',
      template    => 'register_user.md',
      username    => $name->value,
   };
   my $payload = $self->json_parser->encode($params);
   my $cache   = $self->redis_client;

   $cache->set_with_ttl("create_user-${token}", $payload, 259200);

   return $self->send_message($context, $token, $payload);
}

use namespace::autoclean -except => META;

1;
