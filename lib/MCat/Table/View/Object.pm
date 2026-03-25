package MCat::Table::View::Object;

use HTML::StateTable::Constants qw( FALSE SPC TABLE_META TRUE );
use HTML::StateTable::Types     qw( ArrayRef Bool DBIxClass Str );
use Scalar::Util                qw( blessed );
use MCat::Object::View;
use Moo;
use MooX::HandlesVia;
use HTML::StateTable::Moo;

extends 'HTML::StateTable';
with    'HTML::StateTable::Role::Form';

has '+form_classes'          => default => sub { [qw(classic fieldset wide)] };
has '+form_control_location' => default =>
   sub { ['BottomLeft', 'BottomRight'] };
has '+max_width'             => default => '50rem';
has '+no_count'              => default => TRUE;
has '+paging'                => default => FALSE;

has 'add_columns' =>
   is          => 'ro',
   isa         => ArrayRef,
   default     => sub { [] },
   handles_via => 'Array',
   handles     => { has_add_columns => 'count' };

has 'add_columns_first' => is => 'ro', isa => Bool, default => FALSE;

has 'result' => is => 'ro', isa => DBIxClass, required => TRUE;

has 'table_class' => is => 'ro', isa => Str, default => 'object-view';

around '_serialise_buttons' => sub {
   my ($orig, $self) = @_;

   my $context = $self->context;
   my $buttons = { BottomLeft => [], BottomRight => [] };

   for my $button (@{$orig->($self)}) {
      my $location = $button->{classes} eq 'left'
         ? 'BottomLeft' : 'BottomRight';

      if (blessed $button->{action}) { push @{$buttons->{$location}}, $button }
      else {
         my $action    = $button->{action}->[0];
         my ($moniker) = split m{ / }mx, $action;
         my $model     = $context->models->{$moniker};

         next unless $model->is_authorised($context, $action);

         $button->{action} = $context->uri_for_action(@{$button->{action}});
         push @{$buttons->{$location}}, $button;
      }
   }

   $context->clear_redirect;
   return $buttons;
};

setup_resultset sub { MCat::Object::View->new(table => shift) };

set_table_name 'object-view';

has_column 'name' =>
   label   => SPC,
   options => { notraits => TRUE },
   width   => '8rem';

has_column 'value' => label => SPC, min_width => '20rem';

use namespace::autoclean -except => TABLE_META;

1;
