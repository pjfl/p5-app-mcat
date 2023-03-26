package MCat::API::Table;

use HTML::Forms::Constants qw( DOT EXCEPTION_CLASS FALSE NUL TRUE );
use HTML::Forms::Types     qw( Str );
use JSON::MaybeXS          qw( );
use Type::Utils            qw( class_type );
use Unexpected::Functions  qw( throw UnknownModel );
use Moo;

has 'name' => is => 'ro', isa => Str, required => TRUE;

has '_json' => is => 'ro', isa => class_type(JSON::MaybeXS::JSON),
   default => sub { JSON::MaybeXS->new( convert_blessed => TRUE ) };

sub action {
   my ($self, $context, @args) = @_;

   return unless $context->posted;

   my $data = $context->get_body_parameters->{data};
   my ($moniker, $method) = split m{ / }mx, $data->{action};

   throw UnknownModel, [$moniker] unless exists $context->models->{$moniker};

   $context->models->{$moniker}->execute($context, $method);
   return;
}

sub preference {
   my ($self, $context, @args) = @_;

   my $name  = $self->_preference_name;
   my $value = $context->get_body_parameters->{data} if $context->posted;
   my $pref  = $self->_preference($context, $name, $value);

   $context->stash( body => $self->_json->encode($pref ? $pref->value : {}) );
   return;
}

# Private methods
sub _preference { # Accessor/mutator with builtin clearer. Store "" to delete
   my ($self, $context, $name, $value) = @_;

   return unless $name;

   my $rs = $context->model('Preference');

   return $rs->update_or_create( # Mutator
      { name => $name, value => $value }, { key => 'preference_name' }
   ) if $value && $value ne '""';

   my $pref = $rs->find({ name => $name }, { key => 'preference_name' });

   return $pref->delete if defined $pref && defined $value; # Clearer

   return $pref; # Accessor
}

sub _preference_name {
   return 'table' . DOT . shift->name . DOT . 'preference';
}

use namespace::autoclean;

1;
