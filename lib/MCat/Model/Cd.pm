package MCat::Model::Cd;

use HTML::Forms::Constants qw( EXCEPTION_CLASS );
use MCat::Util             qw( redirect register_action_paths );
use Unexpected::Functions  qw( UnknownCd Unspecified );
use Web::Simple;

extends 'MCat::Model';
with    'Web::Components::Role';

has '+moniker' => default => 'cd';

register_action_paths 'cd', {
   create => 'artist/*/cd/create',
   delete => 'cd/*/delete',
   edit   => 'cd/*/edit',
   list   => [ 'artist/*/cd', 'cd' ],
   view   => 'cd/*',
};

sub create {
   my ($self, $context, $artistid) = @_;

   return $self->error($context, Unspecified, ['artistid']) unless $artistid;

   my $options = {
      artistid   => $artistid,
      context    => $context,
      item_class => 'Cd',
      title      => 'Create CD',
   };
   my $form = $self->form->new_with_context('Cd', $options);

   if ($form->process( posted => $context->posted )) {
      my $cd_view = $context->uri_for_action('cd/view', [$form->item->id]);
      my $message = ['CD [_1] created', $form->item->title];

      $context->stash( redirect $cd_view, $message );
   }

   $context->stash( form => $form );
   return;
}

sub delete {
   my ($self, $context, $cdid) = @_;

   return unless $self->has_valid_token($context);

   return $self->error($context, Unspecified, ['cdid']) unless $cdid;

   my $cd = $context->model('Cd')->find($cdid);

   return $self->error($context, UnknownCd, [$cdid]) unless $cd;

   my $artistid = $cd->artistid;
   my $title    = $cd->title;

   $cd->delete;

   my $cd_list = $context->uri_for_action('cd/list', [$artistid]);

   $context->stash( redirect $cd_list, ['CD [_1] deleted', $title] );
   return;
}

sub edit {
   my ($self, $context, $cdid) = @_;

   return $self->error($context, Unspecified, ['cdid']) unless $cdid;

   my $cd = $context->model('Cd')->find($cdid);

   return $self->error($context, UnknownCd, [$cdid]) unless $cd;

   my $artistid = $cd->artist->artistid;
   my $options  = {
      artistid => $artistid,
      context  => $context,
      item     => $cd,
      title    => 'Edit CD'
   };
   my $form     = $self->form->new_with_context('Cd', $options);

   if ($form->process( posted => $context->posted )) {
      my $cd_view = $context->uri_for_action('cd/view', [$cdid]);
      my $message = ['CD [_1] updated', $form->item->title];

      $context->stash( redirect $cd_view, $message );
   }

   $context->stash( form => $form );
   return;
}

sub list {
   my ($self, $context, $artistid) = @_;

   my $cd_rs = $context->model('Cd');

   $cd_rs = $cd_rs->search({ artistid => $artistid }) if $artistid;

   my $options = { context => $context, resultset => $cd_rs };

   $context->stash(
      artistid => $artistid,
      table    => $self->table->new_with_context('Cd', $options),
   );
   return;
}

sub view {
   my ($self, $context, $cdid) = @_;

   return $self->error($context, Unspecified, ['cdid']) unless $cdid;

   my $cd = $context->model('Cd')->find($cdid);

   return $self->error($context, UnknownCd, [$cdid]) unless $cd;

   my $track_rs = $context->model('Track')->search({ cdid => $cdid });
   my $options  = { context => $context, resultset => $track_rs };

   $context->stash(
      cd    => $cd,
      table => $self->table->new_with_context('Track', $options)
   );
   return;
}

use namespace::autoclean;

1;
