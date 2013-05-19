package Schema::Result::MimeAttribute;

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

Schema::Result::MimeAttribute

=cut

__PACKAGE__->table("mime_attribute");

=head1 ACCESSORS

=head2 sha1

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 40

=head2 type

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 subtype

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 message_id

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 date

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 from_addr

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 row_ts

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "sha1",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 40 },
  "type",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "subtype",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "message_id",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "date",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "from_addr",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "row_ts",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("sha1");

=head1 RELATIONS

=head2 sha1

Type: belongs_to

Related object: L<Schema::Result::MimeObject>

=cut

__PACKAGE__->belongs_to(
  "sha1",
  "Schema::Result::MimeObject",
  { sha1 => "sha1" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-05-18 23:54:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Pes8uYMN8sKMErHIKkYpGQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
