package Schema::Result::MailFolder;

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

Schema::Result::MailFolder

=cut

__PACKAGE__->table("mail_folder");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 pid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 1

=head2 order

  data_type: 'tinyint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 mailbox_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "pid",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "order",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "mailbox_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("mailbox_id", ["mailbox_id", "pid", "name"]);

=head1 RELATIONS

=head2 pid

Type: belongs_to

Related object: L<Schema::Result::MailFolder>

=cut

__PACKAGE__->belongs_to(
  "pid",
  "Schema::Result::MailFolder",
  { id => "pid" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 mail_folders

Type: has_many

Related object: L<Schema::Result::MailFolder>

=cut

__PACKAGE__->has_many(
  "mail_folders",
  "Schema::Result::MailFolder",
  { "foreign.pid" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mailbox

Type: belongs_to

Related object: L<Schema::Result::Mailbox>

=cut

__PACKAGE__->belongs_to(
  "mailbox",
  "Schema::Result::Mailbox",
  { id => "mailbox_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 mail_messages

Type: has_many

Related object: L<Schema::Result::MailMessage>

=cut

__PACKAGE__->has_many(
  "mail_messages",
  "Schema::Result::MailMessage",
  { "foreign.pid" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-05-18 23:54:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NWKfDHEyM0o/7H7xz0fbVw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;