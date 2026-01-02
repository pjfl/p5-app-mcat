package MCat::Form::TOTP::Reset;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE META NUL TRUE );
use MCat::Util             qw( create_token redirect );
use Type::Utils            qw( class_type );
use Unexpected::Functions  qw( catch_class );
use Try::Tiny;
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms';
with    'HTML::Forms::Role::Defaults';

has 'config' => is => 'lazy', default => sub { shift->context->config };

has 'user' =>
   is       => 'ro',
   isa      => class_type('MCat::Schema::Result::User'),
   required => TRUE;

with 'MCat::Role::Redis';
with 'MCat::Role::JSONParser';

has '+name'              => default => 'TOTP_Reset';
has '+title'             => default => 'TOTP Reset Request';
has '+info_message'      => default => 'Answer the security questions';
has '+no_update'         => default => TRUE;
has '+redis_client_name' => default => 'job_stash';

has_field 'name' => type => 'Display', label => 'User Name';

has_field 'password' => type => 'Password', required => TRUE;

has_field 'mobile_phone' =>
   type     => 'PosInteger',
   label    => 'Mobile #',
   required => TRUE,
   size     => 12;

has_field 'postcode' => required => TRUE, size => 8;

has_field 'submit' => type => 'Button';

sub default_name {
   my $self = shift; return $self->user->name;
}

sub validate {
   my $self   = shift;
   my $user   = $self->user;
   my $passwd = $self->field('password');

   try {
      $user->authenticate($passwd->value, NUL, TRUE);

      my $field = $self->field('mobile_phone');
      my $value = $field->value;

      $field->add_error($value ? 'Invalid response' : 'Required')
         unless $value && $value == $user->mobile_phone;

      $field = $self->field('postcode');
      $value = $field->value;

      $field->add_error($value ? 'Invalid response' : 'Required')
         unless $value && $value eq $user->postcode;

      unless ($self->result->has_errors) {
         $user->assert_can_email;
         $self->context->stash(job => $self->_create_email($user));
      }
   }
   catch_class [
      'Authentication' => sub { $passwd->add_error($_->original) },
      '*' => sub {
         $self->add_form_error($_->original);
         $self->log->alert($_->original, $self->context) if $self->has_log;
      }
   ];

   return;
}

sub _create_email {
   my ($self, $user) = @_;

   my $token   = create_token;
   my $context = $self->context;
   my $actionp = 'misc/totp_reset';
   my $link    = $context->uri_for_action($actionp, [$user->id, $token]);

   $self->redis_client->set($token, $self->json_parser->encode({
      application => $self->config->name,
      link        => "${link}",
      recipients  => [$user->id],
      subject     => '2FA Authenticator Reset',
      template    => 'totp_reset.md',
   }));

   my $prefix  = $self->config->prefix;
   my $program = $self->config->bin->catfile("${prefix}-cli");
   my $command = "${program} -o token=${token} send_message email";
   my $options = { command => $command, name => 'send_message' };

   return $context->model('Job')->create($options);
}

use namespace::autoclean -except => META;

1;
