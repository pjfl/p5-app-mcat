package MCat::Config;

use utf8; # -*- coding: utf-8; -*-

use English                qw( -no_match_vars );
use File::DataClass::IO    qw( io );
use File::DataClass::Types qw( Path Directory File LoadableClass
                               OctalNum Undef );
use HTML::Forms::Constants qw( FALSE NUL TRUE );
use HTML::Forms::Types     qw( ArrayRef Bool HashRef Object PositiveInt Str );
use HTML::Forms::Util      qw( cipher );
use IO::Socket::SSL        qw( SSL_VERIFY_NONE );
use MCat::Util             qw( base64_decode local_tz );
use MCat::Exception;
use Class::Usul::Cmd::Constants qw();
use HTML::StateTable::Constants qw();
use Web::ComposableRequest::Constants qw();
use Moo;

with 'MCat::Config::Loader';

my $except = [
   qw( BUILDARGS BUILD DOES connect_info has_config_file has_config_home
       has_local_config_file new SSL_VERIFY_NONE )
];

Class::Usul::Cmd::Constants->Dump_Except($except);
HTML::Forms::Constants->Exception_Class('MCat::Exception');
HTML::StateTable::Constants->Exception_Class('MCat::Exception');
Web::ComposableRequest::Constants->Exception_Class('MCat::Exception');

=encoding utf-8

=head1 Name

MCat::Config - Configuration class for the Music Catalog

=head1 Synopsis

   use MCat::Config;

=head1 Description

Configuration attribute defaults are overridden by loading a configuration
file. An optional local configuration file can also be read

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item appclass

The application class name. Required by component loader to find controllers,
models, and views

=cut

has 'appclass' => is => 'ro', isa => Str, required => TRUE;

=item appldir

A synonym for 'home'

=cut

has 'appldir' => is => 'lazy', isa => Directory, default => sub { shift->home };

=item authentication

Configuration parameters for the plugin authentication system

=cut

has 'authentication' => is => 'ro', isa => HashRef,
   default => sub { { default_realm => 'DBIC' } };

=item bin

A directory object which locates the applications executable files

=cut

has 'bin' => is => 'lazy', isa => Directory,
   default => sub { shift->pathname->parent };

=item connect_info

Used to connect to the database, the 'dsn', 'db_username', and 'db_password'
attributes are returned in an array reference. The password will be decoded
and decrypted

=cut

has 'connect_info' => is => 'lazy', isa => ArrayRef, default => sub {
   my $self     = shift;
   my $password = cipher->decrypt(base64_decode $self->db_password);

   return [$self->dsn, $self->db_username, $password, $self->db_extra];
};

=item db_extra

Additional attributes passed to the database connection method

=cut

has 'db_extra' => is => 'ro', isa => HashRef,
   default => sub { { AutoCommit => TRUE } };

=item db_password

Password used to connect to the database. This has no default. It should be
set using the command 'bin/mcat-cli --set-db-password' before the application
is started

=cut

has 'db_password' => is => 'ro', isa => Str;

=item db_username

The username used to connect to the database

=cut

has 'db_username' => is => 'ro', isa => Str, default => 'mcat';

=item default_password

The password used when creating new users

=cut

has 'default_password' => is => 'ro', isa => Str, default => 'welcome';

=item default_route

The applications default route used as a target for redirects when the
request does get as far as the mount point

=cut

has 'default_route' => is => 'ro', isa => Str, default => '/mcat/artist';

=item default_view

The default is to create HTML pages. Model methods can rely on this being
set automatically

=cut

has 'default_view' => is => 'ro', isa => Str, default => 'html';

=item deflate_types

List of mime types that the middleware will compress on the fly if the
request allows for it

=cut

has 'deflate_types' => is => 'ro', isa => ArrayRef[Str], default => sub {
   [ qw( text/css text/html text/javascript application/javascript ) ]
};

=item dsn

String used to select a database type and specific database by name

=cut

has 'dsn' => is => 'ro', isa => Str, default => 'dbi:Pg:dbname=mcat';

=item encoding

The output encoding used by the application

=cut

has 'encoding' => is => 'ro', isa => Str, default => 'utf-8';

=item filemanager

A hash reference of parameters used to configure the file manager

=cut

has 'filemanager' =>
   is      => 'lazy',
   isa     => HashRef,
   default => sub {
      my $self = shift;

      return {
         directory  => $self->vardir->catdir('filemanager'),
         extensions => 'csv|txt',
         sharedir   => $self->root->catdir('file')
      };
   };

=item layout

The name of the default template to render

=cut

has 'layout' => is => 'ro', isa => Str, default => 'not_found';

=item loader_attr

Configuration parameters used by the component loader

=cut

has 'loader_attr' => is => 'ro', isa => HashRef, default => sub {
   return { should_log_errors => FALSE, should_log_messages => TRUE };
};

=item locale

Locale used if an attempt is made to localise error messages

=cut

has 'locale' => is => 'ro', isa => Str, default => 'en_GB';

=item lock_attributes

=cut

has 'lock_attributes' => is => 'lazy', isa => HashRef, default => sub {
   my $self = shift;

   return {
      name  => $self->prefix . '_locks',
      redis => $self->redis,
      type  => 'redis',
   };
};

=item logdir

Directory containing logfiles

=cut

has 'logdir' => is => 'lazy', isa => Directory,
   default => sub { shift->vardir->catdir('log') };

=item logfile

Set in the configuration file, the name of the logfile used by the logging
class

=cut

has 'logfile' =>
   is       => 'lazy',
   isa      => File|Path|Undef,
   init_arg => undef,
   default  => sub {
      my $self = shift; return $self->logdir->catfile($self->_logfile);
   };

has '_logfile' => is => 'ro', isa => Str, init_arg => 'logfile';

=item mount_point

Where the application mounts on the base of the request

=cut

has 'mount_point' => is => 'ro', isa => Str, default => '/mcat';

=item name

The display name for the applicaton

=cut

has 'name' => is => 'ro', isa => Str, default => 'Music Catalog';

=item navigation

Hash reference of configuration attributes applied the the L<MCat::Navigation>
object

=cut

has 'navigation' => is => 'lazy', isa => HashRef, init_arg => undef,
   default => sub {
      my $self = shift;

      return {
         messages => {
            'buffer-limit' => $self->request->{max_messages}
         },
         title => $self->name . ' v' . MCat->VERSION,
         title_abbrev => $self->appclass,
         %{$self->_navigation},
         global => [
            qw( admin/menu manager/menu artist/list cd/list track/list )
         ],
      };
   };

has '_navigation' => is => 'ro', isa => HashRef, init_arg => 'navigation',
   default => sub { {} };

=item navigation_manager

Name of the JS navigation management object

=cut

has 'navigation_manager' => is => 'ro', isa => Str,
   default => 'MCat.Navigation.manager';

=item page

Defines the names of the C<site/html> and C<site/wrapper> templates used to
produce all the pages

=cut

has 'page' => is => 'ro', isa => HashRef,
   default => sub { { html => 'base', wrapper => 'standard' } };

=item pathname

File object for absolute pathname to the running program

=cut

has 'pathname' => is => 'ro', isa => File, default => sub {
   my $name = $PROGRAM_NAME;

   $name = '-' eq substr($name, 0, 1) ? $EXECUTABLE_NAME : $name;

   return io((split m{ [ ][\-][ ] }mx, $name)[0])->absolute;
};

=item prefix

Used as a prefix when creating identifiers

=cut

has 'prefix' => is => 'ro', isa => Str, default => 'mcat';

=item redirect

The default action path to redirect to after logging in, changing password etc.

=cut

has 'redirect' => is => 'ro', isa => Str, default => 'artist/list';

=item redis

Configuration hash reference used to configure the connection to the Redis
cache

=cut

has 'redis' => is => 'ro', isa => HashRef, default => sub { {} };

=item registration

Boolean which defaults false. If true user registration is allowed otherwise
it is unavailable

=cut

has 'registration' => is => 'ro', isa => Bool, coerce => TRUE, default => FALSE;

=item request

Hash reference passed to the request object factory constructor by the
component loader. Includes;

=over 3

=item max_messages

The maximum number of response to post messages to buffer both in the session
object where they are stored and the JS object where they are displayed

=item prefix

See 'prefix'

=item request_roles

List of roles to be applied to the request class base

=item serialise_session_attr

List of session attributes that are included for serialisation to the CSRF
token

=item session_attr

A list of names, types, and default values. These are composed into the
session object

=back

=cut

has 'request' => is => 'lazy', isa => HashRef, default => sub {
   my $self = shift;

   return {
      max_messages => 3,
      prefix => $self->prefix,
      request_roles => [ qw( L10N Session JSON Cookie Headers Compat ) ],
      serialise_session_attr => [ qw( id ) ],
      session_attr => {
         email         => [ Str, NUL ],
         enable_2fa    => [ Bool, FALSE ],
         id            => [ PositiveInt, 0 ],
         link_display  => [ Str, 'both' ],
         menu_location => [ Str, 'header' ],
         realm         => [ Str, NUL ],
         role          => [ Str, NUL ],
         skin          => [ Str, $self->skin ],
         theme         => [ Str, 'light' ],
         timezone      => [ Str, local_tz ],
         wanted        => [ Str, NUL ],
      },
   };
};

=item root

Directory which is the document root for assets being served by the application

=cut

has 'root' => is => 'lazy', isa => Directory,
   default => sub { shift->vardir->catdir('root') };

=item rundir

Used to store runtime files

=cut

has 'rundir' => is => 'lazy', isa => Directory,
   default => sub { shift->tempdir };

=item schema_class

The name of the lazily loaded database schema class

=cut

has 'schema_class' => is => 'lazy', isa => LoadableClass, coerce => TRUE,
   default => 'MCat::Schema';

=item script

Name of the program being executed. Appears on the manual page output

=cut

has 'script' => is => 'lazy', isa => Str,
   default => sub { shift->pathname->basename };

=item skin

The templates used to render the pages of the application can be created in
multiple sets. This is the name of the default set of templates

=cut

has 'skin' => is => 'ro', isa => Str, default => 'classic';

=item sqldir

Directory object which contains the SQL DDL files used to create, populate
and upgrade the database

=cut

has 'sqldir' => is => 'lazy', isa => Directory,
   default => sub { shift->vardir->catdir('sql') };

=item static

Pipe separated list of files and directories under the document root that
should be served statically by the middleware

=cut

has 'static' => is => 'ro', isa => Str,
   default => 'css | file | font | img | js';

=item tempdir

The temporary directory used by the application

=cut

has 'tempdir' => is => 'lazy', isa => Directory,
   default => sub { shift->vardir->catdir('tmp') };

=item token_lifetime

Time in seconds the CSRF token has to live before it is declared invalid

=cut

has 'token_lifetime' => is => 'ro', isa => PositiveInt, default => 3_600;

=item transport_attr

Configuration for sending emails

=cut

has 'transport_attr' => is => 'lazy', isa => HashRef, init_arg => undef,
   default => sub {
      return {
         ssl_options => { SSL_verify_mode => SSL_VERIFY_NONE },
         %{shift->_transport_attr}
      };
   };

has '_transport_attr' => is => 'ro', isa => HashRef, default => sub { {} },
   init_arg => 'transport_attr';

=item umask

Umask set before any methods are executed by the command line dispatcher

=cut

has 'umask' => is => 'ro', isa => OctalNum, coerce => TRUE, default => '027';

=item user

Configuration options for the 'User' result class. Includes 'load_factor'
used in the encrypting of passwords

=cut

has 'user' => is => 'ro', isa => HashRef,
   default => sub { { load_factor => 14 } };

=item vardir

Directory where all non program files and directories are expected to be found

=cut

has 'vardir' => is => 'ro', isa => Directory, coerce => TRUE,
   default => sub { io[qw( var )] };

use namespace::autoclean;

1;

__END__

=back

=head1 Subroutines/Methods

None

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=MCat.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <lazarus@roxsoft.co.uk> >>

=head1 License and Copyright

Copyright (c) 2023 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
