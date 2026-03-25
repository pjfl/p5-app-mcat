package MCat::API::Artist;

use MCat::Constants qw( API_META FALSE TRUE );
use HTTP::Status    qw( HTTP_CREATED );
use Moo;
use MCat::API::Moo;

extends 'MCat::API::Base';
with    'Web::Components::Role';

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
      name        => '',
      type        => '',
      description => '',
   }],
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

use namespace::autoclean -except => API_META;

1;

