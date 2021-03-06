package MimeCas::Schema::Result::MimeObject;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("mime_object");
__PACKAGE__->add_columns(
  "sha1",
  { data_type => "char", is_nullable => 0, size => 40 },
  "content",
  { data_type => "longtext", is_nullable => 0 },
  "parsed",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "parse_error",
  { data_type => "text", is_nullable => 1 },
  "direct_children",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "all_children",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "virtual_size",
  { data_type => "integer", is_nullable => 1 },
  "actual_size",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("sha1");
__PACKAGE__->has_many(
  "mail_messages",
  "MimeCas::Schema::Result::MailMessage",
  { "foreign.sha1" => "self.sha1" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->might_have(
  "mime_attribute",
  "MimeCas::Schema::Result::MimeAttribute",
  { "foreign.sha1" => "self.sha1" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "mime_graph_child_sha1s",
  "MimeCas::Schema::Result::MimeGraph",
  { "foreign.child_sha1" => "self.sha1" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "mime_graph_parent_sha1s",
  "MimeCas::Schema::Result::MimeGraph",
  { "foreign.parent_sha1" => "self.sha1" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "mime_headers",
  "MimeCas::Schema::Result::MimeHeader",
  { "foreign.sha1" => "self.sha1" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "mime_recipients",
  "MimeCas::Schema::Result::MimeRecipient",
  { "foreign.sha1" => "self.sha1" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-05-30 13:56:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OF9j++dZ4l0r9T8EqIDdaQ

__PACKAGE__->has_many(
  "parent_objects",
  "MimeCas::Schema::Result::MimeGraph",
  { "foreign.child_sha1" => "self.sha1" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "child_objects",
  "MimeCas::Schema::Result::MimeGraph",
  { "foreign.parent_sha1" => "self.sha1" },
  { cascade_copy => 0, cascade_delete => 0 },
);

use RapidApp::Include qw(sugar perlutil);

use Email::MIME;

sub Mime {
  my $self = shift;
  
  my $MIME = Email::MIME->new($self->content);
  if ($self->direct_children > 0) {
    my $GraphRs = $self->child_objects->search_rs(undef,{
      order_by => { '-asc' => 'ordering' }
    });
    my @parts = map { $_->child_sha1->Mime } ($GraphRs->all);
    $MIME->parts_set( \@parts );
  }
  
  return $MIME;
}


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
