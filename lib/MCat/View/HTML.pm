package MCat::View::HTML;

use HTML::Forms::Constants qw( TRUE );
use HTML::Forms::Util      qw( get_token process_attrs );
use Scalar::Util           qw( weaken );
use Encode                 qw( encode );
use Moo;

with 'Web::Components::Role';
with 'Web::Components::Role::TT';

has '+moniker' => default => 'html';

sub serialize {
   my ($self, $context) = @_;

   my $stash = $self->_add_tt_defaults($context);
   my $html  = encode($self->encoding, $self->render_template($stash));

   return [ $stash->{code}, _header($stash->{http_headers}), [$html] ];
}

sub _build__templater {
   my $self        =  shift;
   my $config      =  $self->config;
   my $args        =  {
      COMPILE_DIR  => $config->tempdir->catdir('ttc'),
      COMPILE_EXT  => 'c',
      ENCODING     => 'utf-8',
      INCLUDE_PATH => [$self->templates->pathname],
      PRE_PROCESS  => $config->skin . '/site/preprocess.tt',
      RELATIVE     => TRUE,
      TRIM         => TRUE,
      WRAPPER      => $config->skin . '/site/wrapper.tt',
   };
   # uncoverable branch true
   my $template    =  Template->new($args) or throw $Template::ERROR;

   return $template;
}

sub _add_tt_defaults {
   my ($self, $context) = @_; weaken $context;

   my $uri_for_action = sub { $context->uri_for_action(@_) };
   my $stash          = {
      get_token      => \&get_token,
      process_attrs  => \&process_attrs,
      uri_for_action => $uri_for_action,
      %{$context->stash},
   };

   return $stash;
}

sub _header {
   return [ 'Content-Type'  => 'text/html', @{ $_[0] // [] } ];
}

use namespace::autoclean;

1;
