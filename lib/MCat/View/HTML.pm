package MCat::View::HTML;

use HTML::Forms::Constants qw( TRUE );
use MCat::Util             qw( dt_from_epoch dt_human encode_for_html );
use Encode                 qw( encode );
use HTML::Entities         qw( encode_entities );
use HTML::Forms::Util      qw( process_attrs );
use HTTP::Status           qw( status_message );
use Scalar::Util           qw( weaken );
use Moo;

with 'Web::Components::Role';
with 'Web::Components::Role::TT';

has '+moniker' => default => 'html';

sub serialize {
   my ($self, $context) = @_;

   $self->_maybe_render_partial($context);

   my $stash = $self->_add_tt_functions($context);
   my $html  = encode($self->encoding, $self->render_template($stash));

   return [ $stash->{code}, _header($stash->{http_headers}), [$html] ];
}

sub _build__templater {
   my $self        =  shift;
   my $config      =  $self->config;
   my $args        =  {
      COMPILE_DIR  => $config->tempdir->catdir('ttc')->pathname,
      COMPILE_EXT  => 'c',
      ENCODING     => $config->encoding,
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

sub _add_tt_functions {
   my ($self, $context) = @_;

   weaken $context;

   my $tz = $context->time_zone;

   return {
      %{$context->stash},
      dt_from_epoch   => sub { dt_from_epoch shift, $tz },
      dt_human        => \&dt_human,
      dt_user         => sub { my $dt = shift; $dt->set_time_zone($tz); $dt },
      encode_entities => \&encode_entities,
      encode_for_html => \&encode_for_html,
      process_attrs   => \&process_attrs,
      status_message  => \&status_message,
      uri_for         => sub { $context->request->uri_for(@_) },
      uri_for_action  => sub { $context->uri_for_action(@_) },
   };
}

sub _header {
   return [ 'Content-Type' => 'text/html', @{ $_[0] // [] } ];
}

sub _maybe_render_partial {
   my ($self, $context) = @_;

   my $header = $context->request->header('Prefer') // q();

   return unless $header eq 'render=partial';

   my $page = $context->stash('page') // {};

   $page->{html} = 'none';
   $page->{wrapper} = 'none';
   $context->stash(page => $page);
   return;
}

use namespace::autoclean;

1;
