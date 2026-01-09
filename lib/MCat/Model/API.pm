package MCat::Model::API;

use MCat::Constants qw( DOT EXCEPTION_CLASS FALSE TRUE );
use HTTP::Status    qw( HTTP_OK );
use DateTime::TimeZone;
use Try::Tiny;
use Moo;
use MCat::Navigation::Attributes; # Will do namespace cleaning

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'api';

sub form : Auth('none') Capture(1) {
   my ($self, $context, $name) = @_;

   $name =~ s{ _ }{::}gmx;

   $context->stash(form => $self->new_form($name, { context => $context }));
   return;
}

sub field : Auth('none') Capture(1) {
   my ($self, $context, $name) = @_;

   $context->stash(field => $context->stash('form')->field($name));
   return;
}

sub object : Auth('none') Capture(1) {
   my ($self, $context, $name) = @_;

   $context->stash(object_name => $name);
   return;
}

sub table : Auth('none') Capture(1) {
   my ($self, $context, $name) = @_;

   $context->stash(table_name => $name);
   return;
}

sub action : Auth('view') {
   my ($self, $context) = @_;

   my $data = $context->get_body_parameters->{data};
   my ($moniker, $method) = split m{ / }mx, $data->{action};

   if (exists $context->models->{$moniker}) {
      try   { $context->models->{$moniker}->execute($context, $method) }
      catch { $self->log->error($_, $context) };
   }
   else { $self->log->error("Model ${moniker} unknown", $context) }

   $self->_stash_result($context);
   return;
}

sub collect_messages : Auth('none') {
   my ($self, $context) = @_;

   my $session  = $context->session;
   my $messages = $session->collect_status_messages($context->request);

   $self->_stash_result($context, [ reverse @{$messages} ]);
   return;
}

sub fetch : Auth('none') {
   my ($self, $context) = @_;

   my $name   = $context->stash('object_name');
   my $method = "_fetch_${name}";
   my $result = {};

   if ($self->can($method)) {
      try   { $result = $self->$method($context) }
      catch { $self->log->error($_, $context) };
   }
   else { $self->log->error("Object ${name} unknown", $context) }

   $self->_stash_result($context, $result);
   return;
}

sub preference : Auth('view') {
   my ($self, $context) = @_;

   my $name  = $self->_preference_name($context);
   my $value = $context->get_body_parameters->{data} if $context->posted;
   my $pref  = $self->_preference($context, $name, $value);

   $self->_stash_result($context, $pref ? $pref->value : {});
   return;
}

sub validate : Auth('none') {
   my ($self, $context) = @_;

   my $form  = $context->stash('form');
   my $field = $context->stash('field');
   my $value = $context->request->query_parameters->{value};

   $form->setup_form({ $field->name => $value });
   $field->validate_field;
   $self->_stash_result($context, { reason => [$field->result->all_errors] });
   return;
}

# Private methods
sub _fetch_list_name {
   my ($self, $context) = @_;

   my $list_id = $context->request->query_parameters->{list_id};

   return { list_name => $context->model('List')->find($list_id)->name };
}

sub _fetch_property {
   my ($self, $context) = @_;

   my $request = $context->request;
   my $class   = $request->query_params->('class');
   my $prop    = $request->query_params->('property');
   my $value   = $request->query_params->('value', { raw => TRUE });
   my $result  = { found => \0 };

   return $result unless defined $value;

   my $r = $context->model($class)->find_by_key($value);

   $result->{found} = \1 if $r && $r->execute($prop);

   return $result;
}

sub _fetch_timezones {
   return { timezones => [DateTime::TimeZone->all_names] };
}

sub _preference { # Accessor/mutator with builtin clearer. Store "" to delete
   my ($self, $context, $name, $value) = @_;

   return unless $name;

   my $rs = $context->model('Preference');

   return $rs->update_or_create({ # Mutator
      name => $name, user_id => $context->session->id, value => $value
   }, { key => 'preference_user_id_name_uniq' }) if $value && $value ne '""';

   my $pref = $rs->find({
      name => $name, user_id => $context->session->id
   }, { key => 'preference_user_id_name_uniq' });

   return $pref->delete if defined $pref && defined $value; # Clearer

   return $pref; # Accessor
}

sub _preference_name {
   my ($self, $context) = @_;

   return 'table' . DOT . $context->stash('table_name') . DOT . 'preference';
}

sub _stash_result {
   my ($self, $context, $result) = @_;

   $result //= {};
   $context->stash(code => HTTP_OK, json => $result, view => 'json');
   return;
}

1;
