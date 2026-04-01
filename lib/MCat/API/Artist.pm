package MCat::API::Artist;

use MCat::Constants       qw( API_META EXCEPTION_CLASS FALSE NUL TRUE );
use HTTP::Status          qw( HTTP_CREATED HTTP_FORBIDDEN HTTP_NO_CONTENT );
use Unexpected::Functions qw( throw );
use Moo;
use MCat::API::Moo;

extends 'MCat::API::Base';
with    'Web::Components::Role';

my $class = __PACKAGE__;

has '+moniker' => default => 'artist';

has '+result_class' => default => 'Artist';

has_api_column 'artistid' =>
   type        => 'int',
   description => 'The unique identifier for this artist.',
   methods     => { get => TRUE, search => TRUE };

has_api_column 'name' =>
   type        => 'str',
   description => 'The name of the artist.',
   methods     => { get => TRUE, search => TRUE };

has_api_column 'name' =>
   type        => 'str',
   description => 'The name of the artist. Maximum 255 characters.',
   methods     => { create => TRUE, update => TRUE },
   constraints => {
      constraints      => {
         name          => {
            max_length => 255,
            min_length => 3,
            pattern    => '\A [0-9A-Za-z_ ]+ \z',
         },
      },
      fields           => {
         name          => {
            validate   => 'isMandatory isMatchingRegex isValidLength',
         },
      },
   };

has_api_column 'active' =>
   type        => 'bool',
   description => 'Is this artist still active.',
   methods     => {
      get => TRUE, search => TRUE, create => TRUE, update => TRUE
   };

has_api_column 'upvotes' =>
   type        => 'int',
   description => 'Number of upvotes recieved by this artist.',
   methods     => {
      get => TRUE, search => TRUE, create => TRUE, update => TRUE
   };

has_api_column 'import_log_id' =>
   type        => 'int',
   description => 'Unique import ID assigned if this artist was imported.',
   methods     => { get => TRUE, search => TRUE };

has_api_method 'search' =>
   route       => '/artist',
   action      => 'search',
   description => q(
      Searches all artists, returning those matching your specified
      criteria as [% transport_type('array_of_hash') | indefinite_article %].
      You can supply any number of search criteria from the list shown.

      Optionally, you can paginate the output by passing page and page_size
      parameters.
   ),
   in_args     => [{
      name        => 'search',
      type        => 'hash',
      description => q(
         [% transport_type | ucfirst %] representing the values on which to
         search for matching artists.
      ),
      fields      => 'search',
      location    => 'query',
   }, $class->arguments_pageing],
   out_arg      => {
      name        => 'artists',
      type        => 'array',
      description => q(
         Returns the found artists as
         [% transport_type('array_of_hash') | indefinite_article %].
      ),
      fields      => 'get',
   },
   examples    => [{
      name        => 'Get All Artists',
      description => 'Get all artists, limited to 1 per page',
      url         => '/artist?page_size=1',
      response    => [{
         artistid      => 1,
         name          => 'Deep Purple',
         active        => \1,
         upvotes       => 70,
         import_log_id => NUL,
      }],
   }];

has_api_method 'create' =>
   access       => { write => TRUE, read => FALSE },
   method       => 'POST',
   route        => '/artist',
   action       => 'create',
   success_code => HTTP_CREATED,
   description  => q(
      Creates a new artist. The return value is
      [% transport_type('hash') | indefinite_article %] containing your new
      artist, including its unique ID.
    ),
   in_args      => [{
      name        => 'create',
      type        => 'hash',
      description => 'Initial values for your new artist.',
      fields      => 'create',
      location    => 'body',
   }],
   out_arg      => {
      name        => 'artist',
      type        => 'hash',
      description => q(
         [% transport_type | indefinite_article | ucfirst %] representing
         the artist matching the given ID.
      ),
      fields      => 'get',
   },
   examples     => [{
      name     => 'Create an Artist',
      body     => {
         name    => 'Hawkwind',
         active  => \1,
         upvotes => 50,
      },
      response => {
         artist_id     => 2,
         name          => 'Hawkwind',
         active        => \1,
         upvotes       => 50,
         import_log_id => NUL,
      },
   }];

has_api_method 'get' =>
   route       => '/artist/{artistid:[0-9]+}',
   action      => 'get',
   description => q(
      Fetches a artist by ID, and returns
      [% transport_type('hash') | indefinite_article %] containing the details
      of that artist.
   ),
   in_args     => [{
      name        => 'artistid',
      type        => 'int',
      description => 'ID of the artist.',
      location    => 'path',
   }],
   out_arg     => {
      name        => 'artist',
      type        => 'hash',
      description => q(
         [% transport_type | indefinite_article | ucfirst %] representing
         the artist matching the given ID.
      ),
      fields      => 'get',
   },
   examples    => [{
      name        => 'Get Artist ID 1',
      url         => '/artist/1',
      response    => {
         artistid      => 1,
         name          => 'Deep Purple',
         active        => \1,
         upvotes       => 70,
         import_log_id => NUL,
      },
   }];

has_api_method 'update' =>
   access      => { write => TRUE, read => FALSE },
   method      => 'PUT',
   route       => '/artist/{artistid:[0-9]+}',
   action      => 'update',
   description => 'Updates one or more values for a given artist.',
   in_args     => [{
      name        => 'artistid',
      type        => 'int',
      description => 'ID of the artist you wish to update.',
      location    => 'path',
   },{
      name        => 'update',
      type        => 'hash',
      description => q(
         New values for the fields of your artist which you wish to
         change. Any values not present in this [% transport_type %] will be
         left unaltered.
      ),
      fields      => 'update',
      location    => 'body',
   }],
   out_arg     => {
      name        => 'artist',
      type        => 'hash',
      description => q(
         [% transport_type | indefinite_article | ucfirst %] representing
         the artist matching the given ID.
      ),
      fields      => 'get',
   },
   examples    => [{
      name     => 'Update an Artist',
      url      => '/artist/2',
      body     => { upvotes => 90 },
      response => {
         artist_id     => 2,
         name          => 'Hawkwind',
         active        => \1,
         upvotes       => 90,
         import_log_id => NUL,
      },
   }];

has_api_method 'delete' =>
   access       => { write => TRUE, read => FALSE },
   method       => 'DELETE',
   route        => '/artist/{artistid:[0-9]+}',
   action       => 'delete',
   success_code => HTTP_NO_CONTENT,
   description  => 'Delete the specified artist.',
   in_args      => [{
      name        => 'artistid',
      type        => 'int',
      description => 'ID of the artist you wish to delete.',
      location    => 'path',
   }],
   examples     => [{
      name => 'Delete an Artist',
      url  => '/artist/2',
   }];

sub check_create_permission {
   my ($self, $context) = @_;

   throw 'No create permission', rv => HTTP_FORBIDDEN
      unless $self->_is_authorised($context, 'artist/create');

   return;
}

sub check_delete_permission {
   my ($self, $context) = @_;

   throw 'No delete permission', rv => HTTP_FORBIDDEN
      unless $self->_is_authorised($context, 'artist/delete');

   return;
}

sub check_search_permission {
   my ($self, $context) = @_;

   throw 'No search permission', rv => HTTP_FORBIDDEN
      unless $self->_is_authorised($context, 'artist/list');

   return;
}

sub check_update_permission {
   my ($self, $context) = @_;

   throw 'No update permission', rv => HTTP_FORBIDDEN
      unless $self->_is_authorised($context, 'artist/edit');

   return;
}

use namespace::autoclean -except => API_META;

1;

