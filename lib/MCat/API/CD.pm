package MCat::API::CD;

use MCat::Constants       qw( API_META EXCEPTION_CLASS FALSE NUL TRUE );
use HTTP::Status          qw( HTTP_CREATED HTTP_FORBIDDEN HTTP_NO_CONTENT );
use Unexpected::Functions qw( throw );
use Moo;
use MCat::API::Moo;

extends 'MCat::API::Base';
with    'Web::Components::Role';

my $class = __PACKAGE__;

has '+moniker' => default => 'cd';

has '+result_class' => default => 'Cd';

has_api_column 'cdid' =>
   type        => 'int',
   description => 'The unique identifier for this CD.',
   methods     => { get => TRUE, search => TRUE };

has_api_column 'artistid' =>
   type        => 'int',
   description => 'The unique identifier for this artist.',
   methods     => {
      create => TRUE, get => TRUE, search => TRUE, update => TRUE,
   };

has_api_column 'title' =>
   type        => 'str',
   description => 'The title of the CD.',
   methods     => { get => TRUE, search => TRUE };

has_api_column 'title' =>
   type        => 'str',
   description => 'The title of the CD. Maximum 255 characters.',
   methods     => { create => TRUE, update => TRUE },
   constraints => {
      options  => {
         max_length => 255,
         min_length => 3,
         pattern    => '\A [0-9A-Za-z_ ]+ \z',
      },
      actions  => {
         validate => 'isMandatory isMatchingRegex isValidLength',
      },
   };

has_api_column 'year' =>
   type        => 'datetime',
   description => 'The year in which the CD was released.',
   methods     => {
      create => TRUE, get => TRUE, search => TRUE, update => TRUE,
   };

has_api_column 'import_log_id' =>
   type        => 'int',
   description => 'Unique import ID assigned if this CD was imported.',
   methods     => { get => TRUE, search => TRUE };

has_api_method 'search' =>
   route       => '/cd',
   action      => 'search',
   description => q(
      Searches all CDs, returning those matching your specified
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
         search for matching CDs.
      ),
      fields      => 'search',
      location    => 'query',
   }, $class->arguments_pageing],
   out_arg      => {
      name        => 'cds',
      type        => 'array',
      description => q(
         Returns the found CDs as
         [% transport_type('array_of_hash') | indefinite_article %].
      ),
      fields      => 'get',
   },
   examples    => [{
      name        => 'Get All CDs',
      description => 'Get all CDs, limited to 1 per page',
      url         => '/cd?page_size=1',
      response    => [{
         cdid          => 1,
         artistid      => 1,
         title         => 'White Albumn',
         year          => '2023-02-16T00:00:00',
         import_log_id => NUL,
      }],
   }];

has_api_method 'create' =>
   access       => { write => TRUE, read => FALSE },
   method       => 'POST',
   route        => '/cd',
   action       => 'create',
   success_code => HTTP_CREATED,
   description  => q(
      Creates a new CD. The return value is
      [% transport_type('hash') | indefinite_article %] containing your new
      CD, including its unique ID.
   ),
   in_args      => [{
      name        => 'create',
      type        => 'hash',
      description => 'Initial values for your new CD.',
      fields      => 'create',
      location    => 'body',
   }],
   out_arg      => {
      name        => 'cd',
      type        => 'hash',
      description => q(
         [% transport_type | indefinite_article | ucfirst %] representing
         the CD matching the given ID.
      ),
      fields      => 'get',
   },
   examples     => [{
      name     => 'Create a CD',
      body     => {
         artistid => 1,
         title    => 'White Albumn',
         year     => '2023-02-16',
      },
      response => {
         cdid          => 1,
         artistid      => 1,
         title         => 'White Albumn',
         year          => '2023-02-16T00:00:00',
         import_log_id => NUL,
      },
   }];

has_api_method 'get' =>
   route       => '/cd/{cdid:[0-9]+}',
   action      => 'get',
   description => q(
      Fetches a CD by ID, and returns
      [% transport_type('hash') | indefinite_article %] containing the details
      of that CD.
   ),
   in_args     => [{
      name        => 'cdid',
      type        => 'int',
      description => 'ID of the CD.',
      location    => 'path',
   }],
   out_arg     => {
      name        => 'cd',
      type        => 'hash',
      description => q(
         [% transport_type | indefinite_article | ucfirst %] representing
         the CD matching the given ID.
      ),
      fields      => 'get',
   },
   examples    => [{
      name        => 'Get CD ID 1',
      url         => '/cd/1',
      response    => {
         cdid          => 1,
         artistid      => 1,
         title         => 'White Albumn',
         year          => '2023-02-16T00:00:00',
         import_log_id => NUL,
      },
   }];

has_api_method 'update' =>
   access      => { write => TRUE, read => FALSE },
   method      => 'PUT',
   route       => '/cd/{cdid:[0-9]+}',
   action      => 'update',
   description => 'Updates one or more values for a given CD.',
   in_args     => [{
      name        => 'cdid',
      type        => 'int',
      description => 'ID of the CD you wish to update.',
      location    => 'path',
   },{
      name        => 'update',
      type        => 'hash',
      description => q(
         New values for the fields of your CD which you wish to
         change. Any values not present in this [% transport_type %] will be
         left unaltered.
      ),
      fields      => 'update',
      location    => 'body',
   }],
   out_arg     => {
      name        => 'cd',
      type        => 'hash',
      description => q(
         [% transport_type | indefinite_article | ucfirst %] representing
         the CD matching the given ID.
      ),
      fields      => 'get',
   },
   examples    => [{
      name     => 'Update a CD',
      url      => '/cd/2',
      body     => { title => 'Blue Albumn' },
      response => {
         cdid          => 2,
         artistid      => 1,
         title         => 'Blue Albumn',
         year          => '2023-02-16T00:00:00',
         import_log_id => NUL,
      },
   }];

has_api_method 'delete' =>
   access       => { write => TRUE, read => FALSE },
   method       => 'DELETE',
   route        => '/cd/{cdid:[0-9]+}',
   action       => 'delete',
   success_code => HTTP_NO_CONTENT,
   description  => 'Delete the specified CD.',
   in_args      => [{
      name        => 'cdid',
      type        => 'int',
      description => 'ID of the CD you wish to delete.',
      location    => 'path',
   }],
   examples     => [{
      name => 'Delete a CD',
      url  => '/cd/2',
   }];

sub check_create_permission {
   my ($self, $context) = @_;

   throw 'No create permission', rv => HTTP_FORBIDDEN
      unless $self->_is_authorised($context, 'cd/create');

   return;
}

sub check_delete_permission {
   my ($self, $context) = @_;

   throw 'No delete permission', rv => HTTP_FORBIDDEN
      unless $self->_is_authorised($context, 'cd/delete');

   return;
}

sub check_search_permission {
   my ($self, $context) = @_;

   throw 'No search permission', rv => HTTP_FORBIDDEN
      unless $self->_is_authorised($context, 'cd/list');

   return;
}

sub check_update_permission {
   my ($self, $context) = @_;

   throw 'No update permission', rv => HTTP_FORBIDDEN
      unless $self->_is_authorised($context, 'cd/edit');

   return;
}

use namespace::autoclean -except => API_META;

1;
