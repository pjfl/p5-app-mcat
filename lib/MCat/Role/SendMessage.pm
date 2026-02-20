package MCat::Role::SendMessage;

use Moo::Role;

with 'MCat::Role::Redis';

sub send_message {
   my ($self, $context, $token, $payload) = @_;

   $self->redis_client->set_with_ttl("send_message-${token}", $payload, 1800);

   my $prefix  = $self->config->prefix;
   my $program = $self->config->bin->catfile("${prefix}-cli");
   my $command = "${program} -o token=${token} send_message email";
   my $options = { command => $command, name => 'send_message' };

   return $context->model('Job')->create($options);
}

use namespace::autoclean;

1;
