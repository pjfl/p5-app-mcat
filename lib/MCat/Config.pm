package MCat::Config;

use MCat::Constants        qw( FALSE NUL SECRET TRUE );
use IO::Socket::SSL        qw( SSL_VERIFY_NONE );
use File::DataClass::Types qw( ArrayRef Bool Directory File HashRef
                               LoadableClass Object OctalNum Path
                               PositiveInt Str Undef );
use Class::Usul::Cmd::Util qw( decrypt now_dt );
use English                qw( -no_match_vars );
use File::DataClass::IO    qw( io );
use MCat::Util             qw( local_tz );
use Moo;

with 'Web::Components::ConfigLoader';

my $except = [
   qw( BUILDARGS BUILD DOES connect_info has_config_file has_config_home
       has_local_config_file new SSL_VERIFY_NONE )
];

Class::Usul::Cmd::Constants->Dump_Except($except);

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

The application class name. Required by the L<component
loader|Web::Components::Loader> to find controllers, models, and views

=cut

has 'appclass' => is => 'ro', isa => Str, required => TRUE;

=item appldir

A synonym for C<home>

=cut

has 'appldir' => is => 'lazy', isa => Directory, default => sub { shift->home };

=item authentication

Configuration parameters for the plugin authentication system

=cut

has 'authentication' =>
   is      => 'ro',
   isa     => HashRef,
   default => sub { { default_realm => 'DBIC' } };

=item bin

A directory object which locates the applications executable files

=cut

has 'bin' =>
   is      => 'lazy',
   isa     => Directory,
   default => sub { shift->pathname->parent };

=item bug_attachments

A hash reference of parameters used to configure the bug attachment uploads

=cut

has 'bug_attachments' =>
   is      => 'lazy',
   isa     => HashRef,
   default => sub {
      my $self = shift;

      return {
         directory  => $self->vardir->catdir('bugs'),
         extensions => 'csv|doc|png|txt',
         max_size   => 5_120_000,
         sharedir   => $self->root->catdir('bugs')
      };
   };

=item component_loader

Configuration parameters used by the L<component loader|Web::Components::Loader>

=cut

has 'component_loader' =>
   is      => 'ro',
   isa     => HashRef,
   default => sub {
      return { should_log_errors => FALSE, should_log_messages => TRUE };
   };

=item connect_info

Used to connect to the database, the 'dsn', 'db_username', and 'db_password'
attributes are returned in an array reference. The password will be decoded
and decrypted

=cut

has 'connect_info' =>
   is      => 'lazy',
   isa     => ArrayRef,
   default => sub {
      my $self     = shift;
      my $password = decrypt SECRET, $self->db_password;

      return [$self->dsn, $self->db_username, $password, $self->db_extra];
   };

=item copyright_year

Year displayed in the copyright string. Defaults to the current year

=cut

has 'copyright_year' =>
   is      => 'ro',
   isa     => Str,
   default => sub { now_dt->strftime('%Y') };

=item db_extra

Additional attributes passed to the database connection method

=cut

has 'db_extra' =>
   is      => 'ro',
   isa     => HashRef,
   default => sub { { AutoCommit => TRUE } };

=item db_password

Password used to connect to the database. This has no default. It should be
set using the command C<bin/mcat-cli --set-db-password> before the application
is started by the same user as the one which will be running the application

=cut

has 'db_password' => is => 'ro', isa => Str;

=item db_username

The username used to connect to the database

=cut

has 'db_username' => is => 'ro', isa => Str, default => 'mcat';

=item deployment

Defaults to B<development>. Should be overridden in the local configuration
file. Used to modify the server output depending on deployment environment.
For example, any value not C<development> will prevent the rendering of an
exception to the end user

=cut

has 'deployment' => is => 'ro', isa => Str, default => 'development';

=item default_base_colour

Defaults to B<bisque>. Used as the base colour for page rendering. Can be
changed via the user F<Profile> form

=cut

has 'default_base_colour' => is => 'ro', isa => Str, default => 'bisque';

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

The C<moniker> of view that creates HTML pages. Model methods can rely on this
being stashed automatically as the C<view> attribute

=cut

has 'default_view' => is => 'ro', isa => Str, default => 'html';

=item deflate_types

List of mime types that the middleware will compress on the fly if the
request allows for it

=cut

has 'deflate_types' =>
   is      => 'ro',
   isa     => ArrayRef[Str],
   default => sub {
      return [
         qw( application/javascript image/svg+xml text/css text/html
             text/javascript )
      ];
   };

=item documentation

A hash reference of parameters used to configure the documentation viewer

=cut

has 'documentation' =>
   is      => 'lazy',
   isa     => HashRef,
   default => sub {
      my $self = shift;

      return {
         directory  => $self->bin->parent->catdir('lib'),
         extensions => 'pm',
         sharedir   => $self->root->catdir('file')
      };
   };

=item dsn

String used to select a database driver and a specific database by name

=cut

has 'dsn' => is => 'ro', isa => Str, default => 'dbi:Pg:dbname=mcat';

=item enable_advanced

Boolean which defaults to B<false>. If true the F<Profile> form will show the
advanced options

=cut

has 'enable_advanced' => is => 'ro', isa => Bool, default => FALSE;

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

=item fonts

Fonts used in the application pages. Either fetched from Google's CDN or
served locally

=cut

has 'fonts' =>
   is       => 'lazy',
   isa      => HashRef,
   init_arg => undef,
   default  => sub {
      my $self = shift;

      return {
         google_apis   => 'https://fonts.googleapis.com',
         google_static => 'https://fonts.gstatic.com',
         google_fonts  => $self->_google_fonts,
         local_fonts   => $self->_local_fonts,
      };
   };

has '_google_fonts' =>
   is       => 'ro',
   isa      => ArrayRef,
   init_arg => 'google_fonts',
   default  => sub { [] };

has '_local_fonts' =>
   is       => 'ro',
   isa      => ArrayRef,
   init_arg => 'local_fonts',
   default  => sub { [] };

=item footer_links

An array reference of tuples. Each is comprised of; display text for the link,
either an action path or a URI, and if a URI is used set the third argument
to C<true>

=cut

has 'footer_links' => is => 'ro', isa => ArrayRef, default => sub { [] };

=item icons

A partial string path from the document root to the file containing SVG
symbols used when generating HTML

=cut

has 'icons' => is => 'ro', isa => Str, default => 'img/icons.svg';

=item keywords

Space separated list of keywords which appear in the meta of the HTML pages

=cut

has 'keywords' => is => 'ro', isa => Str, default => 'music cataloging';

=item locale

Locale used if an attempt is made to localise error messages

=cut

has 'locale' => is => 'ro', isa => Str, default => 'en_GB';

=item local_tz

The applications local time zone

=cut

has 'local_tz' => is => 'ro', isa => Str, default => 'Europe/London';

=item lock_attributes

Configuration attributes for the L<lock manager|IPC::SRLock>. Currently unused

=cut

has 'lock_attributes' =>
   is      => 'lazy',
   isa     => HashRef,
   default => sub {
      my $self = shift;

      return {
         name  => $self->prefix . '_locks',
         redis => $self->redis,
         type  => 'redis',
      };
   };

=item log_message_maxlen

Maximum length of a logfile message in characters. If zero (the default) no
limit is applied

=cut

has 'log_message_maxlen' => is => 'ro', isa => PositiveInt, default => 0;

=item logsdir

Directory containing logfiles

=cut

has 'logsdir' =>
   is      => 'lazy',
   isa     => Directory,
   default => sub { shift->vardir->catdir('log') };

=item logfile

Set in the configuration file, the name of the logfile used by the logging
class. If left unset the logging class will emit warnings to C<stderr>

=cut

has 'logfile' =>
   is       => 'lazy',
   isa      => File|Path|Undef,
   init_arg => undef,
   default  => sub {
      my $self = shift;

      return unless $self->_logfile;

      return $self->logsdir->catfile($self->_logfile);
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

Hash reference of configuration attributes applied the the
L<navigation|Web::Components::Navigation> object

=cut

has 'navigation' =>
   is       => 'lazy',
   isa      => HashRef,
   init_arg => undef,
   default  => sub {
      my $self = shift;

      return {
         messages     => { 'buffer-limit' => $self->request->{max_messages} },
         title        => $self->name,
         title_abbrev => $self->appclass,
         %{$self->_navigation},
         global       => [
            qw( artist/list cd/list track/list manager/menu admin/menu )
         ],
      };
   };

has '_navigation' =>
   is       => 'ro',
   isa      => HashRef,
   init_arg => 'navigation',
   default  => sub { {} };

=item pathname

File object for absolute pathname to the running program

=cut

has 'pathname' =>
   is      => 'ro',
   isa     => File,
   default => sub {
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

Configuration hash reference used to configure the connection to the L<Redis>
cache

=cut

has 'redis' => is => 'ro', isa => HashRef, default => sub { {} };

=item registration

Boolean which defaults B<false>. If true user registration is allowed otherwise
it is unavailable

=cut

has 'registration' => is => 'ro', isa => Bool, coerce => TRUE, default => FALSE;

=item request

Hash reference passed to the request object factory constructor by the
component loader. Includes; C<max_messages>, C<prefix>, C<request_roles>,
C<serialise_session_attr>, and C<session_attr>

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

has 'request' =>
   is      => 'lazy',
   isa     => HashRef,
   default => sub {
      my $self = shift;

      return {
         max_messages => 3,
         prefix => $self->prefix,
         request_roles => [ qw( L10N Session JSON Cookie Headers Compat ) ],
         serialise_session_attr => [ qw( id ) ],
         session_attr => {
            base_colour   => [ Str, $self->default_base_colour ],
            email         => [ Str, NUL ],
            enable_2fa    => [ Bool, FALSE ],
            id            => [ PositiveInt, 0 ],
            link_display  => [ Str, 'both' ],
            menu_location => [ Str, 'header' ],
            realm         => [ Str, NUL ],
            role          => [ Str, NUL ],
            shiny         => [ Bool, FALSE ],
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

has 'root' =>
   is      => 'lazy',
   isa     => Directory,
   default => sub { shift->vardir->catdir('root') };

=item rundir

Used to store runtime files

=cut

has 'rundir' =>
   is      => 'lazy',
   isa     => Directory,
   default => sub { shift->tempdir };

=item schema_class

The name of the lazily loaded database schema class

=cut

has 'schema_class' =>
   is      => 'lazy',
   isa     => LoadableClass,
   coerce  => TRUE,
   default => 'MCat::Schema';

=item script

Name of the program being executed. Appears on the manual page output

=cut

has 'script' =>
   is      => 'lazy',
   isa     => Str,
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

has 'sqldir' =>
   is      => 'lazy',
   isa     => Directory,
   default => sub { shift->vardir->catdir('sql') };

=item state_cookie

Array reference used to instantiate the
L<session state cookie|Plack::Session::State::Cookie>

=cut

has 'state_cookie' =>
   is      => 'lazy',
   isa     => HashRef,
   default => sub {
      my $self = shift;

      return {
         expires     => 7_776_000,
         httponly    => TRUE,
         path        => $self->mount_point,
         samesite    => 'None',
         secure      => TRUE,
         session_key => $self->prefix . '_session',
      };
   };

=item static

Pipe separated list of files and directories under the document root that
should be served statically by the middleware

=cut

has 'static' =>
   is      => 'ro',
   isa     => Str,
   default => 'css | file | fonts | img | js';

=item tempdir

The temporary directory used by the application

=cut

has 'tempdir' =>
   is      => 'lazy',
   isa     => Directory,
   default => sub { shift->vardir->catdir('tmp') };

=item template_wrappers

Defines the names of the F<site/html> and F<site/wrapper> templates used to
produce all the pages

=cut

has 'template_wrappers' =>
   is      => 'ro',
   isa     => HashRef,
   default => sub { { html => 'base', wrapper => 'standard' } };

=item token_lifetime

Time in seconds the CSRF token has to live before it is declared invalid

=cut

has 'token_lifetime' => is => 'ro', isa => PositiveInt, default => 3_600;

=item transport_attr

Configuration for sending emails

=cut

has 'transport_attr' =>
   is       => 'lazy',
   isa      => HashRef,
   init_arg => undef,
   default  => sub {
      return {
         ssl_options => { SSL_verify_mode => SSL_VERIFY_NONE },
         %{shift->_transport_attr}
      };
   };

has '_transport_attr' =>
   is       => 'ro',
   isa      => HashRef,
   init_arg => 'transport_attr',
   default  => sub { {} };

=item umask

Umask set before any methods are executed by the command line dispatcher

=cut

has 'umask' => is => 'ro', isa => OctalNum, coerce => TRUE, default => '027';

=item user

Configuration options for the F<User> result class. Includes; C<load_factor>,
C<default_password>, C<default_role>, C<min_name_len>, and C<min_password_len>

=over 3

=item C<load_factor>

Used in the encrypting of passwords

=item C<default_password>

Used when creating new users

=item C<default_role>

Used when creating new users

=item C<min_name_len>

Minimum user name length

=item C<min_password_len>

Minumum password length

=back

=cut

has 'user' =>
   is      => 'ro',
   isa     => HashRef,
   default => sub {
      return {
         default_password => 'welcome',
         default_role     => 'view',
         load_factor      => 14,
         min_name_len     => 3,
         min_password_len => 3,
      };
   };

=item vardir

Directory where all non program files and directories are expected to be found

=cut

has 'vardir' =>
   is      => 'ro',
   isa     => Directory,
   coerce  => TRUE,
   default => sub { io[qw( var )] };

=item wcom_resources

Names of the JS management objects

=cut

has 'wcom_resources' =>
   is      => 'ro',
   isa     => HashRef[Str],
   default => sub {
      return {
         data_structure => 'WCom.Form.DataStructure.manager',
         downloadable   => 'WCom.Table.Role.Downloadable',
         form_util      => 'WCom.Form.Util',
         markup         => 'WCom.Util.Markup',
         modal          => 'WCom.Modal',
         navigation     => 'WCom.Navigation.manager',
         table_renderer => 'WCom.Table.Renderer.manager',
      };
   };

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

=item L<Web::Components::ConfigLoader>

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

Copyright (c) 2025 Peter Flanigan. All rights reserved

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
