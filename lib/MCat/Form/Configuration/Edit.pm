package MCat::Form::Configuration::Edit;

use HTML::Forms::Constants qw( FALSE META NUL TRUE );
use HTML::Forms::Types     qw( Str );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms';
with    'HTML::Forms::Role::Defaults';
with    'HTML::Forms::Role::FormBuilder';

has '+info_message' => default => 'Edit the local configuration file values';
has '+name'         => default => 'config_edit';
has '+title'        => default => 'Edit Local Configuration';

has 'config' => is => 'lazy', default => sub { shift->context->config };

has '_icons' =>
   is      => 'lazy',
   isa     => Str,
   default => sub { shift->context->icons_uri->as_string };

has_field 'submit' => type => 'Button';

after 'after_build_fields' => sub {
   my $self  = shift;
   my $count = 1;

   for my $field (@{$self->form_builder($self->config)}) {
      $self->add_field($field);
      $count += 1;
   }

   $self->field('submit')->order($count);
   return;
};

use namespace::autoclean -except => META;

1;
