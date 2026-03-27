package MCat::API::Artist;

use MCat::Constants       qw( API_META EXCEPTION_CLASS FALSE TRUE );
use HTTP::Status          qw( HTTP_CREATED HTTP_UNAUTHORIZED );
use Unexpected::Functions qw( throw );
use Moo;
use MCat::API::Moo;

extends 'MCat::API::Base';
with    'Web::Components::Role';

my $class = __PACKAGE__;

has '+moniker' => default => 'artist';

has '+result_class' => default => 'Artist';

has_api_column 'artistid' =>
   type        => 'Int',
   description => 'The unique identifier for this artist.',
   methods     => { get => TRUE, search => TRUE };

has_api_column 'name' =>
   type        => 'Str',
   description => 'The name of the artist.',
   methods     => { get => TRUE, search => TRUE };

has_api_column 'name' =>
   type        => 'Str',
   description => 'The name of the artist. Maximum 255 characters.',
   methods     => { create => TRUE, update => TRUE };

has_api_column 'active' =>
   type        => 'Bool',
   description => 'Is this artist still active.',
   methods     => {
      get => TRUE, search => TRUE, create => TRUE, update => TRUE
   };

has_api_column 'upvotes' =>
   type        => 'Int',
   description => 'Number of upvotes recieved by this artist.',
   methods     => {
      get => TRUE, search => TRUE, create => TRUE, update => TRUE
   };

has_api_column 'import_log_id' =>
   type        => 'Int',
   description => 'Unique import ID assigned if this artist was imported.',
   methods     => { get => TRUE, search => TRUE };

has_api_method 'search' =>
   route       => '/artist',
   action      => 'search',
   description => '',
   in_args     => [{
      name        => 'search',
      type        => 'hash',
      description => 'Query string representing the values on which to '
                   . 'search for matching artists.',
      location    => 'query',
      fields      => 'search',
   }, $class->arguments_pageing],
   out_arg     => {},
   examples    => [{}];

has_api_method 'create' =>
   access       => { write => TRUE, read => FALSE },
   method       => 'POST',
   route        => '/artist',
   action       => 'create',
   success_code => HTTP_CREATED,
   description  => '',
   in_args      => [{}],
   out_arg      => {},
   examples     => [{}];

has_api_method 'get' =>
   route       => '/artist/*',
   action      => 'get',
   description => 'Fetches an artist by ID, and returns JSON containing'
                . 'the details of that artist.',
   in_args     => [{
      name        => 'artistid',
      type        => 'Int',
      description => 'ID of the artist.',
      location    => 'path',
   }],
   out_arg     => {
      name       => 'artist',
      type       => 'HashRef',
      desciption => 'JSON representing the artist matching the given ID.',
      fields     => 'get',
   },
   examples    => [{}];

has_api_method 'update' =>
   access      => { write => TRUE, read => FALSE },
   method      => 'PUT',
   route       => '/artist/*',
   action      => 'update',
   description => '',
   in_args     => [{}],
   out_arg     => {},
   examples    => [{}];

has_api_method 'delete' =>
   access       => { write => TRUE, read => FALSE },
   method       => 'DELETE',
   route        => '/artist/*',
   action       => 'delete',
   description  => '',
   in_args      => [{}],
   out_arg      => {},
   examples     => [{}];

sub check_create_permission {
   my ($self, $context) = @_;

   throw 'No create permission', rv => HTTP_UNAUTHORIZED
      unless $self->_is_authorised($context, 'artist/create');

   return;
}

sub check_delete_permission {
   my ($self, $context) = @_;

   throw 'No delete permission', rv => HTTP_UNAUTHORIZED
      unless $self->_is_authorised($context, 'artist/delete');

   return;
}

sub check_search_permission {
   my ($self, $context) = @_;

   throw 'No search permission', rv => HTTP_UNAUTHORIZED
      unless $self->_is_authorised($context, 'artist/list');

   return;
}

sub check_update_permission {
   my ($self, $context) = @_;

   throw 'No update permission', rv => HTTP_UNAUTHORIZED
      unless $self->_is_authorised($context, 'artist/edit');

   return;
}

use namespace::autoclean -except => API_META;

1;

