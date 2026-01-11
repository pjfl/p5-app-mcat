package MCat::Model::Bug;

use MCat::Constants       qw( EXCEPTION_CLASS FALSE NUL TRUE );
use Unexpected::Types     qw( Int Str );
use MCat::Util            qw( redirect redirect2referer );
use Unexpected::Functions qw( UnauthorisedAccess UnknownAttachment UnknownBug );
use Moo;
use MCat::Navigation::Attributes; # Will do cleaning

extends 'MCat::Model';
with    'Web::Components::Role';
with    'MCat::Role::FileMeta';

has '+moniker' => default => 'bug';

sub base : Auth('none') {
   my ($self, $context) = @_;

   $context->stash('nav')->list('bugs')->finalise;

   return;
}

sub bugid : Auth('none') Capture(1) {
   my ($self, $context, $bugid) = @_;

   my $bug = $context->model('Bug')->find($bugid, { prefetch => [
      'owner',
      'assigned',
      { attachments => 'owner' },
      { comments    => 'owner' },
   ]});

   return $self->error($context, UnknownBug, [$bugid]) unless $bug;

   $context->stash(bug => $bug);

   my $nav = $context->stash('nav')->list('bugs');

   $nav->crud('bug', $bugid)->finalise;
   return;
}

sub attach {
   my ($self, $context) = @_;

   my $bug     = $context->stash('bug');
   my $options = {
      bug        => $bug,
      context    => $context,
      extensions => $self->file_extensions,
      file       => $self->file,
      max_size   => $self->file_max_size,
   };
   my $form    = $self->new_form('BugAttachment', $options);

   if ($form->process(posted => $context->posted)) {
      my $params   = { 'current-page' => 2 };
      my $edit     = $context->uri_for_action('bug/edit', [$bug->id], $params);
      my $filename = $form->destination;

      $context->stash(redirect $edit, ['File [_1] uploaded', $filename]);
      return;
   }

   $context->stash(form => $form);
   return;
}

sub attachment : Auth('view') {
   my ($self, $context, $attachment_id) = @_;

   my $attachment = $context->model('BugAttachment')->find($attachment_id);

   return $self->error($context, UnknownAttachment, [$attachment_id])
      unless $attachment;

   my $params = $context->request->query_parameters;

   if (exists $params->{download} and $params->{download} eq 'true') {
      my $name = $attachment->path;
      my $fml  = qq{attachment; filename="${name}"; filename*=UTF-8''${name}};

      $context->stash(
         http_headers => ['Content-Disposition', $fml],
         content_path => $attachment->content_path($self->file),
         view         => 'image'
      );
   }
   elsif (exists $params->{thumbnail} and $params->{thumbnail} eq 'true') {
      $context->stash(
         content_path => $attachment->content_path($self->file),
         thumbnail    => TRUE,
         view         => 'image'
      );
   }
   else {
      my $options = { attachment => $attachment, context => $context };

      $context->stash(form => $self->new_form('AttachmentView', $options));
   }

   return;
}

sub create : Auth('view') Nav('Report Bug') {
   my ($self, $context) = @_;

   my $form = $self->new_form('BugReport', { context => $context });

   if ($form->process(posted => $context->posted)) {
      my $bugid    = $form->item->id;
      my $username = $context->session->username;
      my $view     = $context->uri_for_action('bug/view', [$bugid]);
      my $message  = ['User [_1] bug report [_2] created', $username, $bugid];

      $context->stash(redirect $view, $message);
   }

   $context->stash(form => $form);
   return;
}

sub delete : Auth('admin') Nav('Delete Bug') {
   my ($self, $context) = @_;

   return unless $self->verify_form_post($context);

   my $bug   = $context->stash('bug');
   my $bugid = $bug->id;

   $bug->delete;

   my $list = $context->uri_for_action('bug/list');

   $context->stash(redirect $list, ['Bug report [_1] deleted', $bugid]);
   return;
}

sub edit : Nav('Update Bug') {
   my ($self, $context) = @_;

   my $bug     = $context->stash('bug');
   my $options = {
      context      => $context,
      info_message => 'Edit bug details',
      item         => $bug,
      title        => 'Update Bug',
   };
   my $form = $self->new_form('BugReport', $options);

   return $self->error($context, UnauthorisedAccess, [])
      if $context->posted && !$form->is_editor;

   if ($form->process(posted => $context->posted)) {
      my $purged  = $bug->purge_attachments;
      my $params  = $purged ? { 'current-page' => 2 } : {};
      my $edit    = $context->uri_for_action('bug/edit', [$bug->id], $params);
      my $message = ['Bug report [_1] updated', $bug->id];

      $message = ['Attactment [_1] deleted', join ', ', @{$purged}]
         if $purged;

      $context->stash(redirect $edit, $message);
   }

   $context->stash(form => $form);
   return;
}

sub list : Auth('view') Nav('Bugs') {
   my ($self, $context) = @_;

   my $table = $self->new_table('Bugs', { context => $context });

   $context->stash(table => $table);
   return;
}

sub remove : Auth('admin') {
   my ($self, $context) = @_;

   return unless $self->verify_form_post($context);

   my $value = $context->get_body_parameters->{data} or return;
   my $rs    = $context->model('Bug');
   my $ids   = [];

   for my $bug (grep { $_ } map { $rs->find($_) } @{$value->{selector}}) {
      push @{$ids}, $bug->id;
      $bug->delete;
   }

   my $message = ['Bug report(s) [_1] deleted', (join ', ', @{$ids})];

   $context->stash(redirect2referer $context, $message);
   return;
}

sub view : Auth('view') Nav('View Bug') {
   my ($self, $context) = @_;

   my $bug = $context->stash('bug');
   my $buttons = [{
      action    => $context->uri_for_action('bug/list'),
      method    => 'get',
      selection => 'disable_on_select',
      value     => 'List',
   },{
      action    => $context->uri_for_action('bug/edit', [$bug->id]),
      classes   => 'right',
      method    => 'get',
      selection => 'disable_on_select',
      value     => 'Update',
   }];
   my $options = {
      caption      => 'View Bug',
      context      => $context,
      form_buttons => $buttons,
      result       => $bug,
   };

   $context->stash(table => $self->new_table('View::Object', $options));
   return;
}

1;
