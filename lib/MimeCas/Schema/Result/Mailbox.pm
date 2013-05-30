package MimeCas::Schema::Result::Mailbox;

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

MimeCas::Schema::Result::Mailbox

=cut

__PACKAGE__->table("mailbox");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 realm

  data_type: 'varchar'
  default_value: '(default)'
  is_nullable: 0
  size: 255

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 description

  data_type: 'varchar'
  is_nullable: 1
  size: 512

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "realm",
  {
    data_type => "varchar",
    default_value => "(default)",
    is_nullable => 0,
    size => 255,
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "description",
  { data_type => "varchar", is_nullable => 1, size => 512 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("realm", ["realm", "name"]);

=head1 RELATIONS

=head2 mail_folders

Type: has_many

Related object: L<MimeCas::Schema::Result::MailFolder>

=cut

__PACKAGE__->has_many(
  "mail_folders",
  "MimeCas::Schema::Result::MailFolder",
  { "foreign.mailbox_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mail_messages

Type: has_many

Related object: L<MimeCas::Schema::Result::MailMessage>

=cut

__PACKAGE__->has_many(
  "mail_messages",
  "MimeCas::Schema::Result::MailMessage",
  { "foreign.mailbox_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-05-29 22:08:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CRZOJcxVnfrW/6Zi0zpXCw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
