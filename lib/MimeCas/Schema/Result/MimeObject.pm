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

=head1 NAME

MimeCas::Schema::Result::MimeObject

=cut

__PACKAGE__->table("mime_object");

=head1 ACCESSORS

=head2 sha1

  data_type: 'char'
  is_nullable: 0
  size: 40

=head2 content

  data_type: 'longtext'
  is_nullable: 0

=head2 children

  data_type: 'tinyint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "sha1",
  { data_type => "char", is_nullable => 0, size => 40 },
  "content",
  { data_type => "longtext", is_nullable => 0 },
  "children",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("sha1");

=head1 RELATIONS

=head2 mail_messages

Type: has_many

Related object: L<MimeCas::Schema::Result::MailMessage>

=cut

__PACKAGE__->has_many(
  "mail_messages",
  "MimeCas::Schema::Result::MailMessage",
  { "foreign.sha1" => "self.sha1" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mime_attribute

Type: might_have

Related object: L<MimeCas::Schema::Result::MimeAttribute>

=cut

__PACKAGE__->might_have(
  "mime_attribute",
  "MimeCas::Schema::Result::MimeAttribute",
  { "foreign.sha1" => "self.sha1" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mime_graph_child_sha1s

Type: has_many

Related object: L<MimeCas::Schema::Result::MimeGraph>

=cut

__PACKAGE__->has_many(
  "mime_graph_child_sha1s",
  "MimeCas::Schema::Result::MimeGraph",
  { "foreign.child_sha1" => "self.sha1" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mime_graph_parent_sha1s

Type: has_many

Related object: L<MimeCas::Schema::Result::MimeGraph>

=cut

__PACKAGE__->has_many(
  "mime_graph_parent_sha1s",
  "MimeCas::Schema::Result::MimeGraph",
  { "foreign.parent_sha1" => "self.sha1" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mime_headers

Type: has_many

Related object: L<MimeCas::Schema::Result::MimeHeader>

=cut

__PACKAGE__->has_many(
  "mime_headers",
  "MimeCas::Schema::Result::MimeHeader",
  { "foreign.sha1" => "self.sha1" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mime_recipients

Type: has_many

Related object: L<MimeCas::Schema::Result::MimeRecipient>

=cut

__PACKAGE__->has_many(
  "mime_recipients",
  "MimeCas::Schema::Result::MimeRecipient",
  { "foreign.sha1" => "self.sha1" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-05-19 02:09:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UAfGStESVOKMbD7IYO1Z0g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
