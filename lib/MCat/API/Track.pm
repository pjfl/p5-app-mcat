package MCat::API::Track;

use Web::Components::API::Constants
                 qw( API_META FALSE NUL TRUE );
use HTTP::Status qw( HTTP_CREATED HTTP_NO_CONTENT );
use Moo;
use Web::Components::API::Moo;

extends 'Web::Components::API::Base';
with    'Web::Components::Role';

my $class = __PACKAGE__;

has '+moniker' => default => 'track';

has '+result_class' => default => 'Track';

has_api_column 'trackid' =>
   type        => 'int',
   description => 'The unique identifier for this track.',
   methods     => { get => TRUE, search => TRUE };

has_api_column 'cdid' =>
   type        => 'int',
   description => 'The unique identifier for this CD.',
   methods     => {
      create => TRUE, get => TRUE, search => TRUE, update => TRUE,
   };

has_api_column 'title' =>
   type        => 'str',
   description => 'The title of the track.',
   methods     => { get => TRUE, search => TRUE };

has_api_column 'title' =>
   type        => 'str',
   description => 'The title of the track. Maximum 255 characters.',
   methods     => { create => TRUE, update => TRUE },
   constraints => {
      actions  => {
         validate => 'Mandatory MatchingRegex ValidLength',
      },
      options  => {
         max_length => 255,
         min_length => 3,
         pattern    => '\A [0-9A-Za-z_ ]+ \z',
      },
   };

has_api_column 'import_log_id' =>
   type        => 'int',
   description => 'unique import id assigned if this track was imported.',
   methods     => { get => TRUE, search => TRUE };

has_api_method 'search' =>
   route       => '/track',
   action      => 'search',
   access      => 'track/list',
   description => q(
      Searches all tracks, returning those matching your specified
      criteria as [% transport_type('array_of_hash') | indefinite_article %].
      you can supply any number of search criteria from the list shown.

      Optionally, you can paginate the output by passing page and page_size
      parameters.
   ),
   in_args     => [{
      name        => 'search',
      type        => 'hash',
      description => q(
         [% transport_type | ucfirst %] representing the values on which to
         search for matching tracks.
      ),
      fields      => 'search',
      location    => 'query',
   }, $class->arguments_pageing],
   out_arg      => {
      name        => 'tracks',
      type        => 'array',
      description => q(
         Returns the found tracks as
         [% transport_type('array_of_hash') | indefinite_article %].
      ),
      fields      => 'get',
   },
   examples    => [{
      name        => 'Get All Tracks',
      description => 'Get all tracks, limited to 1 per page',
      url         => '/track?page_size=1',
      response    => [{
         trackid       => 1,
         cdid          => 1,
         title         => 'Generic Track Title',
         import_log_id => NUL,
      }],
   }];

has_api_method 'create' =>
   method       => 'POST',
   route        => '/track',
   action       => 'create',
   access       => 'track/create',
   success_code => HTTP_CREATED,
   description  => q(
      Creates a new track. The return value is
      [% transport_type('hash') | indefinite_article %] containing your new
      track, including its unique ID.
   ),
   in_args      => [{
      name        => 'create',
      type        => 'hash',
      description => 'Initial values for your new track.',
      fields      => 'create',
      location    => 'body',
   }],
   out_arg      => {
      name        => 'track',
      type        => 'hash',
      description => q(
         [% transport_type | indefinite_article | ucfirst %] representing
         the track matching the given ID.
      ),
      fields      => 'get',
   },
   examples     => [{
      name     => 'Create a track',
      body     => {
         cdid  => 1,
         title => 'Generic Track Title',
      },
      response => {
         trackid       => 1,
         cdid          => 1,
         title         => 'Generic Track Title',
         import_log_id => NUL,
      },
   }];

has_api_method 'get' =>
   route       => '/track/{trackid:[0-9]+}',
   action      => 'get',
   access      => 'track/view',
   description => q(
      Fetches a track by ID, and returns
      [% transport_type('hash') | indefinite_article %] containing the details
      of that track.
   ),
   in_args     => [{
      name        => 'trackid',
      type        => 'int',
      description => 'ID of the track.',
      location    => 'path',
   }],
   out_arg     => {
      name        => 'track',
      type        => 'hash',
      description => q(
         [% transport_type | indefinite_article | ucfirst %] representing
         the track matching the given ID.
      ),
      fields      => 'get',
   },
   examples    => [{
      name        => 'Get track ID 1',
      url         => '/track/1',
      response    => {
         trackid       => 1,
         cdid          => 1,
         title         => 'Generic Track Title',
         import_log_id => NUL,
      },
   }];

has_api_method 'update' =>
   method      => 'PUT',
   route       => '/track/{trackid:[0-9]+}',
   action      => 'update',
   access      => 'track/edit',
   description => 'Updates one or more values for a given track.',
   in_args     => [{
      name        => 'trackid',
      type        => 'int',
      description => 'ID of the track you wish to update.',
      location    => 'path',
   },{
      name        => 'update',
      type        => 'hash',
      description => q(
         New values for the fields of your track which you wish to
         change. Any values not present in this [% transport_type %] will be
         left unaltered.
      ),
      fields      => 'update',
      location    => 'body',
   }],
   out_arg     => {
      name        => 'track',
      type        => 'hash',
      description => q(
         [% transport_type | indefinite_article | ucfirst %] representing
         the track matching the given ID.
      ),
      fields      => 'get',
   },
   examples    => [{
      name     => 'Update a track',
      url      => '/track/2',
      body     => { title => 'Number 2 Snigger' },
      response => {
         trackid       => 2,
         cdid          => 1,
         title         => 'Number 2 Snigger',
         import_log_id => NUL,
      },
   }];

has_api_method 'delete' =>
   access       => 'track/delete',
   method       => 'DELETE',
   route        => '/track/{trackid:[0-9]+}',
   action       => 'delete',
   success_code => HTTP_NO_CONTENT,
   description  => 'Delete the specified track.',
   in_args      => [{
      name        => 'trackid',
      type        => 'int',
      description => 'ID of the track you wish to delete.',
      location    => 'path',
   }],
   examples     => [{
      name => 'Delete a track',
      url  => '/track/2',
   }];

use namespace::autoclean -except => API_META;

1;
