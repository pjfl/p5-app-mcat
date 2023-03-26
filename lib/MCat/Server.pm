package MCat::Server;

use MCat;
use MCat::Config;
use MCat::Log;
use MCat::Session;
use HTML::Forms::Constants qw( FALSE NUL TRUE );
use HTML::Forms::Types     qw( HashRef Object Str );
use HTTP::Status           qw( HTTP_FOUND );
use Type::Utils            qw( class_type );
use Plack::Builder;
use Web::Simple;

has '_config_attr' =>
   is       => 'ro',
   isa      => HashRef,
   init_arg => 'config',
   builder  => sub { { appclass => 'MCat' } };

has 'config' =>
   is      => 'lazy',
   isa     => class_type('MCat::Config'),
   builder => sub { MCat::Config->new( shift->_config_attr ) };

has 'log' =>
   is      => 'lazy',
   isa     => class_type('MCat::Log'),
   builder => sub { MCat::Log->new( config => shift->config ) };

has 'session' =>
   is      => 'lazy',
   isa     => class_type('MCat::Session'),
   builder => sub { MCat::Session->new( config => shift->config ) };

with 'Web::Components::Loader';

around 'to_psgi_app' => sub {
   my ($orig, $self, @args) = @_;

   my $psgi_app = $orig->($self, @args);
   my $config   = $self->config;
   my $static   = $config->static;

   return builder {
      enable 'ConditionalGET';
      enable 'Options', allowed => [ qw( DELETE GET POST PUT HEAD ) ];
      enable 'Head';
      enable 'ContentLength';
      enable 'FixMissingBodyInRedirect';
      enable 'Deflater',
         content_type => $config->deflate_types, vary_user_agent => TRUE;
      enable 'Static',
         path => qr{ \A / (?: $static) }mx, root => $config->root;
      mount $config->mount_point => builder {
         enable 'Session', $self->session->middleware_config;
         $psgi_app;
      };
      mount '/' => builder {
         sub { [ HTTP_FOUND, [ 'Location', $config->default_route ], [] ] }
      };
   };
};

sub BUILD {
   my $self   = shift;
   my $server = ucfirst($ENV{PLACK_ENV} // NUL);
   my $class  = $self->config->appclass;
   my $info   = 'v' . $class->VERSION;
   my $port   = $ENV{ uc "${class}_port" } // 5_000;

   $info .= " started on port ${port}";
   $self->log->info("Server: ${class} ${server} ${info}");
   return;
}

sub _build__factory {
   my $self = shift;

   return Web::ComposableRequest->new(
      buildargs => $self->factory_args,
      config    => $self->config->request,
   );
}

use namespace::autoclean;

1;
