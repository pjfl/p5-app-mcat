package MCat::Form::Configuration::Edit;

use HTML::Forms::Constants qw( FALSE META TRUE );
use HTML::Forms::Types     qw( Str );
use Web::Components::Util  qw( dump_file load_file );
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms';
with    'HTML::Forms::Role::Defaults';
with    'HTML::Forms::Role::FormBuilder';

has '+include_private' => default => TRUE;
has '+info_message'    => default => 'Edit the local configuration file values';
has '+name'            => default => 'config_edit';
has '+title'           => default => 'Edit Local Configuration';

has 'config' => is => 'lazy', default => sub { shift->context->config };

has '_icons' =>
   is      => 'lazy',
   isa     => Str,
   default => sub { shift->context->icons_uri->as_string };

has_field 'submit' => type => 'Button';

after 'after_build_fields' => sub {
   my $self  = shift;
   my $count = 1;

   for my $field (@{$self->field_builder($self->config)}) {
      $self->add_field($field);
      $count += 1;
   }

   $self->field('submit')->order($count);
   return;
};

sub update_model {
   my $self       = shift;
   my $for_update = TRUE;
   my $changed    = $self->changed_fields($self->config, $for_update);
   my $content    = load_file $self->config->local_config_file, $for_update;
   my $combined   = $self->merge_changed($self->config, $changed, $content);

   dump_file $self->config->local_config_file, $combined;

   my $prefix  = $self->config->prefix;
   my $program = $self->config->bin->catfile("${prefix}-cli");
   my $command = "${program} server-restart";
   my $options = { command => $command, name => 'send_message' };

   $self->context->model('Job')->create($options);
   return;
}

use namespace::autoclean -except => META;

1;
