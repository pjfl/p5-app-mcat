package MCat::Server;

use HTML::Forms::Constants qw( FALSE NUL TRUE );
use HTTP::Status           qw( HTTP_FOUND );
use Class::Usul::Cmd::Util qw( ns_environment );

use MCat;
use Plack::Builder;
use Web::Simple;

with 'MCat::Role::Config';
with 'MCat::Role::Log';
with 'MCat::Role::Session';
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
         content_type    => $config->deflate_types,
         vary_user_agent => TRUE;
      mount $config->mount_point => builder {
         enable 'Static',
            path => qr{ \A / (?: $static) }mx,
            root => $config->root;
         enable 'Session', $self->session->middleware_config;
         enable 'LogDispatch', logger => $self->log;
         $psgi_app;
      };
      mount '/' => builder {
         sub { [ HTTP_FOUND, [ 'Location', $config->default_route ], [] ] }
      };
   };
};

sub BUILD {
   my $self   = shift;
   my $class  = $self->config->appclass;
   my $server = ucfirst($ENV{PLACK_ENV} // NUL);
   my $port   = ns_environment($class, 'port') // 5_000;
   my $info   = 'v' . $class->VERSION . " started on port ${port}";

   $self->log->info("HTTPServer: ${class} ${server} ${info}");
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
