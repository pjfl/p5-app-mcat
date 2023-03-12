package MCat::API::Table;

use HTML::Forms::Constants qw( EXCEPTION_CLASS DOT NUL TRUE );
use HTML::Forms::Types     qw( Object Str );
use JSON::MaybeXS          qw( encode_json );
use Unexpected::Functions  qw( throw UnknownModel );
use Moo;

has 'form' => is => 'ro', isa => Object, required => TRUE;

has 'name' => is => 'ro', isa => Str, required => TRUE;

sub action {
   my ($self, $context, @args) = @_;

   return unless $context->posted;

   my $data = $self->form->get_body_parameters($context)->{data};
   my ($moniker, $method) = split m{ / }mx, $data->{action};

   throw UnknownModel, [$moniker] unless exists $context->models->{$moniker};

   $context->models->{$moniker}->execute($context, $method);
   return;
}

sub preference {
   my ($self, $context, @args) = @_;

   my $name = $self->_preference_name;
   my $pref;

   if ($context->posted) {
      my $value = $self->form->get_body_parameters($context)->{data};

      $pref = $context->preference($name, $value);
   }
   else { $pref = $context->preference($name) }

   $context->stash( body => encode_json($pref ? $pref->value : {}) );
   return;
}

sub _preference_name {
   return 'table' . DOT . shift->name . DOT . 'preference';
}

use namespace::autoclean;

1;
