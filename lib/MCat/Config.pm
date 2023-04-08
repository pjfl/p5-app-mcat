use utf8; # -*- coding: utf-8; -*-
package MCat::Config;

use Class::Usul::Functions qw( base64_decode_ns );
use English                qw( -no_match_vars );
use File::DataClass::IO    qw( io );
use File::DataClass::Types qw( Path Directory OctalNum Undef );
use HTML::Forms::Constants qw( FALSE NUL SECRET TRUE );
use HTML::Forms::Types     qw( ArrayRef HashRef Object PositiveInt Str );
use HTML::Forms::Util      qw( cipher );
use MCat::Util             qw( local_tz );
use MCat::Exception;
use HTML::StateTable::Constants qw();
use Web::ComposableRequest::Constants qw();
use Moo;

with 'MCat::Config::Loader';

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

=item bin

A directory object which locates the applications executable files

=cut

has 'bin' => is => 'lazy', isa => Directory, default => sub {
   my $name = '-' eq substr($PROGRAM_NAME, 0, 1)
      ? $EXECUTABLE_NAME : $PROGRAM_NAME;

   return io((split m{ [ ][\-][ ] }mx, $name)[0])->parent->absolute;
};

=item connect_info

Used to connect to the database, the 'dsn', 'db_username', and 'db_password'
attributes are returned in an array reference. The password will be decoded
and decrypted

=cut

has 'connect_info' => is => 'lazy', isa => ArrayRef, default => sub {
   my $self     = shift;
   my $password = cipher->decrypt(base64_decode_ns $self->db_password);
   my $extra    = { AutoCommit => TRUE };

   return [$self->dsn, $self->db_username, $password, $extra];
};

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
request allow for it

=cut

has 'deflate_types' =>
   is      => 'ro',
   isa     => ArrayRef[Str],
   default => sub {
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

=item logfile

Set in the configuration file, the path to the logfile used by the logging
class

=cut

has 'logfile' => is => 'ro', isa => Path|Undef, coerce => TRUE;

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
         title => $self->name,
         title_abbrev => $self->appclass,
         %{$self->_navigation},
         global => [
            qw( artist/list cd/list track/list admin/menu )
         ],
      };
   };

has '_navigation' => is => 'ro', isa => HashRef, init_arg => 'navigation',
   default => sub { {} };

=item page

Defines the names of the C<site/html> and C<site/wrapper> templates used to
produce all the pages

=cut

has 'page' => is => 'ro', isa => HashRef,
   default => sub { { html => 'base', wrapper => 'standard' } };

=item page_manager

Name of the JS page management object

=cut

has 'page_manager' => is => 'ro', isa => Str,
   default => 'MCat.Navigation.manager';

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
         id       => [ PositiveInt, 0 ],
         role     => [ Str, NUL ],
         timezone => [ Str, local_tz ],
      },
   };
};

=item root

Directory which is the document root for assets being served by the application

=cut

has 'root' => is => 'lazy', isa => Directory,
   default => sub { shift->vardir->catdir('root') };

has 'secret' => is => 'ro', isa => Str, default => SECRET;

=item skin

The templates used to render the pages of the application can be created in
multiple sets. This is the name of the default set of templates

=cut

has 'skin' => is => 'ro', isa => Str, default => 'classic';

=item static

Pipe separated list of files and directories under the document root that
should be served statically by the middleware

=cut

has 'static' =>
   is      => 'ro',
   isa     => Str,
   default => 'css | favicon.ico | fonts | img | js | less';

=item tempdir

The temporary directory used by the application

=cut

has 'tempdir' => is => 'lazy', isa => Directory,
   default => sub { shift->vardir->catdir('tmp') };

=item token_lifetime

Time in seconds the CSRF token has to live before it is declared invalid

=cut

has 'token_lifetime' => is => 'ro', isa => PositiveInt, default => 3_600;

=item user

Configuration options for the 'User' result class. Includes 'load_factor'
used in the encrypting of passwords

=cut

has 'user' => is => 'ro', isa => HashRef,
   default => sub { { load_factor => 14 } };

=item vardir

Directory where all non program files are expected to be found

=cut

has 'vardir' =>
   is      => 'ro',
   isa     => Directory,
   coerce  => TRUE,
   default => sub { io[qw( var )] };

# For the command line help methods to work

=item appldir

A synonym for 'home'

=cut

has 'appldir' => is => 'lazy', isa => Directory, default => sub { shift->home };

=item doc_title

Title used in the production of manual pages

=cut

has 'doc_title' => is => 'ro', isa => Str, default => 'User Documentation';

=item locale

Locale used if an attempt is made to localise error messages

=cut

has 'locale' => is => 'ro', isa => Str, default => 'en_GB';

=item man_page_cmd

Command used to invoke the native manual page viewer

=cut

has 'man_page_cmd' => is => 'ro', isa => ArrayRef,
   default => sub { ['nroff', '-man'] };

=item pwidth

The width of the prompt to use (in characters) when asking for input on the
command line

=cut

has 'pwidth' => is => 'ro', isa => PositiveInt, default => 60;

=item rundir

Defaults the the 'tempdir'. Used to store runtime files

=cut

has 'rundir' => is => 'lazy', isa => Directory,
   default => sub { shift->tempdir };

=item script

Name of the program being used here. Appears on the manual page output

=cut

has 'script' => is => 'lazy', isa => Str, default => sub {
   my $name = '-' eq substr($PROGRAM_NAME, 0, 1)
      ? $EXECUTABLE_NAME : $PROGRAM_NAME;
   my $script = io((split m{ [ ][\-][ ] }mx, $name)[0])->basename;

   return "${script}";
};

=item umask

Umask set before any methods are executed by the command line dispatcher

=cut

has 'umask' => is => 'ro', isa => OctalNum, coerce => TRUE, default => '027';

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
