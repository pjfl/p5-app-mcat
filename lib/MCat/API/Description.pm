package MCat::API::Description;

use overload '""' => sub { shift->_as_string }, fallback => 1;

use MCat::Constants   qw( FALSE NUL TRUE );
use Unexpected::Types qw( HashRef Str );
use Moo;

has 'text' => is => 'ro', isa => Str, required => TRUE;

has 'type' => is => 'ro', isa => Str;

has '_transport_types' =>
   is      => 'ro',
   isa     => HashRef,
   default => sub {
      return {
         'array'         => { name => 'Array' },
         'array_of_hash' => {
            name => 'Array[Object]',
            text => 'array of objects',
         },
         'array_of_int'  => { name => 'Array[Integer]' },
         'bool'          => { name => 'Boolean' },
         'datetime'      => { name => 'DateTime' },
         'dbl'           => { name => 'Double' },
         'hash'          => { name => 'Object' },
         'hash/array_of_hash' => {
            name => 'Object|Array[Object]',
            text => 'object or array of objects',
         },
         'int'           => { name => 'Integer' },
         'str'           => { name => 'String' },
      };
   };

sub _as_string {
   my $self           = shift;
   my $translations   = $self->_transport_types;
   my $placeholder_re = qr{ \[%\s*([^\]]*)%\] }mx;
   my $desc = $self->text;
   my @todo = $desc =~ m{ $placeholder_re }gmx;

   for my $todo (@todo) {
      $todo =~ s{ \A \s+|\s+ \z }{}gmx;

      my ($inline_type) = $todo =~ m{ transport_type\('([^']*)'\) }mx;
      my $type   = $inline_type || $self->type;
      my $output = $translations->{$type}->{text}
                || $translations->{$type}->{name};

      if ($todo =~ m{ indefinite_article }mx) {
         my $article = $output =~ m{ ^[aeiou] }imx ? 'an' : 'a';

         $output = "${article} ${output}";
      }

      $output = ucfirst $output if $todo =~ m{ ucfirst }mx;

      $desc =~ s{ $placeholder_re }{$output}mx;
   }

   return $desc;
}

use namespace::autoclean;

1;
