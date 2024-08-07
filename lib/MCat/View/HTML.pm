package MCat::View::HTML;

use HTML::Forms::Constants qw( TRUE );
use Encode                 qw( encode );
use HTML::Entities         qw( encode_entities );
use HTML::Forms::Util      qw( get_token process_attrs );
use JSON::MaybeXS          qw( encode_json );
use Scalar::Util           qw( weaken );
use Moo;

with 'Web::Components::Role';
with 'Web::Components::Role::TT';

has '+moniker' => default => 'html';

sub serialize {
   my ($self, $context) = @_;

   $self->_maybe_render_partial($context);

   my $stash = $self->_add_tt_defaults($context);
   my $html  = encode($self->encoding, $self->render_template($stash));

   return [ $stash->{code}, _header($stash->{http_headers}), [$html] ];
}

sub _build__templater {
   my $self        =  shift;
   my $config      =  $self->config;
   my $args        =  {
      COMPILE_DIR  => $config->tempdir->catdir('ttc')->pathname,
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

   return {
      context         => $context,
      encode_entities => \&encode_entities,
      encode_for_html => sub { encode_entities(encode_json(@_)) },
      encode_json     => \&encode_json,
      process_attrs   => \&process_attrs,
      token           => sub { $context->verification_token },
      uri_for         => sub { $context->request->uri_for(@_) },
      uri_for_action  => sub { $context->uri_for_action(@_) },
      %{$context->stash},
   };
}

sub _header {
   return [ 'Content-Type'  => 'text/html', @{ $_[0] // [] } ];
}

sub _maybe_render_partial {
   my ($self, $context) = @_;

   my $header = $context->request->header('prefer') // q();

   return unless $header eq 'render=partial';

   my $page = $context->stash('page') // {};

   $page->{html} = 'none';
   $page->{wrapper} = 'none';
   $context->stash(page => $page);
   return;
}

use namespace::autoclean;

1;
