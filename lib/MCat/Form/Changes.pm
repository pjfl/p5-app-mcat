package MCat::Form::Changes;

use HTML::Forms::Constants qw( EXCEPTION_CLASS FALSE META TRUE );
use HTML::Forms::Types     qw( Str );
use Type::Utils            qw( class_type );
use MCat::Markdown;
use Moo;
use HTML::Forms::Moo;

extends 'HTML::Forms';
with    'HTML::Forms::Role::Defaults';

has_field 'changes' => type => 'NonEditable';

has 'formatter' => is => 'lazy', isa => class_type('MCat::Markdown'),
   default => sub { MCat::Markdown->new( tab_width => 3 ) };

around 'after_build_fields' => sub {
   my ($orig, $self) = @_;

   $orig->($self);

   my $config = $self->context->config;
   my $path   = $config->home->catfile('Changes');

   $path = $config->config_home->catfile('Changes') unless $path->exists;

   my $content = join "\n", map { "    ${_}" } $path->getlines;

   $self->field('changes')->html($self->formatter->markdown($content));
   return;
};

use namespace::autoclean -except => META;

1;
