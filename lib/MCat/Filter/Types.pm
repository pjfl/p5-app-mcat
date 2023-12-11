package MCat::Filter::Types;

use strictures;

use Type::Library             -base, -declare =>
                          qw( FilterField FilterNumeric FilterString );
use Type::Utils           qw( as class_type coerce declare extends from
                              message subtype via where );
use Unexpected::Functions qw( inflate_message );

use namespace::clean -except => 'meta';

BEGIN { extends 'Unexpected::Types' };

class_type FilterField, { class => 'MCat::Filter::Type::Field' } ;

coerce FilterField, from Str, via => {
   MCat::Filter::Type::Field->new( name => $_ );
};

coerce FilterField, from HashRef, via => {
   MCat::Filter::Type::Field->new( $_ );
};

class_type FilterNumeric, { class => 'MCat::Filter::Type::Numeric' } ;

coerce FilterNumeric, from Str, via => {
   MCat::Filter::Type::Numeric->new( string => $_ );
};

coerce FilterNumeric, from HashRef, via => {
   MCat::Filter::Type::Numeric->new( $_ );
};

class_type FilterString, { class => 'MCat::Filter::Type::String' } ;

coerce FilterString, from Str, via => {
   MCat::Filter::Type::String->new( string => $_ );
};

coerce FilterString, from HashRef, via => {
   MCat::Filter::Type::String->new( $_ );
};

1;
