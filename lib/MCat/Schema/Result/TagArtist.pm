package MCat::Schema::Result::TagArtist;

use HTML::Forms::Constants qw( FALSE PIPE TRUE );
use DBIx::Class::Moo::ResultClass;

my $class  = __PACKAGE__;
my $result = 'MCat::Schema::Result';

$class->table('tag.artist');

$class->add_columns(
   artistid => { data_type => 'integer' },
   tag_id   => { data_type => 'integer' },
);

$class->set_primary_key(qw( artistid tag_id ));

$class->belongs_to(
   artists => "${result}::Artist", { 'foreign.artistid' => 'self.artistid' }
);

$class->belongs_to(tag => "${result}::Tag", { 'foreign.id' => 'self.tag_id' });

sub insert {
   my $self   = shift;
   my $result = $self->next::method;

   $self->_tag_artist_string_trigger;
   return $result;
}

sub update {
   my ($self, $columns) = @_;

   my $result = $self->next::method($columns);

   $self->_tag_artist_string_trigger;
   return $result;
}

sub _tag_artist_string_trigger {
   my $self       = shift;
   my $source     = $self->result_source;
   my $rs         = $source->resultset;
   my $tag_string =
      join PIPE, map { $_->tag->name }
      $rs->search({ artistid => $self->artistid }, { prefetch => 'tag' })->all;

   $rs = $source->schema->resultset('TagArtistString');
   $rs->update_or_create({ artistid => $self->artistid, name => $tag_string });
   return;
}

1;
