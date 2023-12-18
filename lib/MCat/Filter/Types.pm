package MCat::Filter::Types;

use strictures;

use Type::Library             -base, -declare =>
                          qw( FilterField FilterNumeric FilterString
                              FilterNegate );
use Type::Utils           qw( as class_type coerce declare extends from
                              message subtype via where );
use Unexpected::Functions qw( inflate_message );

BEGIN { extends 'Unexpected::Types' };

class_type FilterField, { class => 'MCat::Filter::Type::Field' };

class_type FilterNumeric, { class => 'MCat::Filter::Type::Numeric' };

class_type FilterString, { class => 'MCat::Filter::Type::String' };

class_type FilterNegate, { class => 'MCat::Filter::Type::Negate' };

coerce FilterField, from Str, via {
   MCat::Filter::Type::Field->new( name => $_ );
};

coerce FilterField, from HashRef, via {
   MCat::Filter::Type::Field->new( $_ );
};

coerce FilterNumeric, from Str, via {
   MCat::Filter::Type::Numeric->new( string => $_ );
};

coerce FilterNumeric, from HashRef, via {
   MCat::Filter::Type::Numeric->new( $_ );
};

coerce FilterString, from Str, via {
   MCat::Filter::Type::String->new( string => $_ );
};

coerce FilterString, from HashRef, via {
   MCat::Filter::Type::String->new( $_ );
};

1;
