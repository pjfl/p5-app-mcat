package MCat::API::Form;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE NUL TRUE );
use HTML::Forms::Types     qw( Str );
use Unexpected::Functions  qw( throw );
use Moo;
use MCat::Navigation::Attributes; # Will do namespace cleaning

has 'name' => is => 'ro', isa => Str, required => TRUE;

sub field : Auth('view') {
   my ($self, $context, $field_name, $operation) = @_;

   my $reason = NUL;

   if ($operation eq 'validate') {
      my $value   = $context->request->query_parameters->{value};
      my $options = { context => $context };
      my $name    = $self->name; $name =~ s{ _ }{::}gmx;
      my $form    = $context->models->{page}->new_form($name, $options);
      my $field   = $form->field($field_name);

      $form->setup_form({ $field_name => $value });
      $field->validate_field;
      $reason = [$field->result->all_errors];
   }
   else { $reason = 'Unknown operation' }

   $context->stash(json => { reason => $reason });
   return;
}

1;
