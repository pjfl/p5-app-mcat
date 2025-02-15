# This file is generated by Dist::Zilla::Plugin::CPANFile v6.030
# Do not edit this file directly. To change prereqs, edit the `dist.ini` file.

requires "App::Job::Daemon" => "v0.1.1";
requires "Auth::GoogleAuth" => "1.05";
requires "CSS::LESS" => "v0.0.3";
requires "Class::Usul::Cmd" => "v0.1.1";
requires "Crypt::Eksblowfish" => "0.009";
requires "DBIx::Class" => "0.082843";
requires "DBIx::Class::Moo::ResultClass" => "0.001001";
requires "Data::Page" => "2.03";
requires "Data::Record" => "0.02";
requires "DateTime" => "1.65";
requires "DateTime::Format::Human" => "0.01";
requires "DateTime::Format::Strptime" => "1.79";
requires "DateTime::TimeZone" => "2.57";
requires "File::DataClass" => "v0.73.1";
requires "Format::Human::Bytes" => "0.06";
requires "HTML::Forms" => "v0.1.1";
requires "HTML::Forms::Model::DBIC" => "v0.1.1";
requires "HTML::Parser" => "3.76";
requires "HTML::StateTable" => "v0.2.1";
requires "HTTP::Message" => "6.44";
requires "IO::Socket::SSL" => "2.074";
requires "IPC::SRLock" => "v0.31.1";
requires "JSON::MaybeXS" => "1.004004";
requires "Moo" => "2.005005";
requires "MooX::HandlesVia" => "0.001009";
requires "Plack" => "1.0050";
requires "Plack::Middleware::Session" => "0.33";
requires "Pod::Markdown::Github" => "0.04";
requires "Redis" => "2.000";
requires "Ref::Util" => "0.204";
requires "Sub::Exporter" => "0.987";
requires "Sub::Install" => "0.929";
requires "Text::CSV_XS" => "1.56";
requires "Text::MultiMarkdown" => "1.000035";
requires "Try::Tiny" => "0.31";
requires "Type::Tiny" => "2.002001";
requires "URI" => "5.17";
requires "Unexpected" => "v1.0.5";
requires "Web::Components" => "v0.12.1";
requires "Web::Components::Role::Email" => "v0.3.1";
requires "Web::Components::Role::TT" => "v0.8.1";
requires "Web::ComposableRequest" => "v0.20.7";
requires "Web::Simple" => "0.033";
requires "local::lib" => "2.000029";
requires "namespace::autoclean" => "0.29";
requires "perl" => "5.010001";
requires "strictures" => "2.000006";

on 'build' => sub {
  requires "Module::Build" => "0.4004";
  requires "version" => "0.88";
};

on 'test' => sub {
  requires "File::Spec" => "0";
  requires "Module::Build" => "0.4004";
  requires "Module::Metadata" => "0";
  requires "Sys::Hostname" => "0";
  requires "Test::Requires" => "0.06";
  requires "version" => "0.88";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "Module::Build" => "0.4004";
  requires "version" => "0.88";
};
