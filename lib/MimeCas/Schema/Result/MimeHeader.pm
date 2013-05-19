package MimeCas::Schema::Result::MimeHeader;

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

MimeCas::Schema::Result::MimeHeader

=cut

__PACKAGE__->table("mime_header");

=head1 ACCESSORS

=head2 sha1

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 40

=head2 order

  data_type: 'tinyint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 value

  data_type: 'varchar'
  is_nullable: 0
  size: 1024

=cut

__PACKAGE__->add_columns(
  "sha1",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 40 },
  "order",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "value",
  { data_type => "varchar", is_nullable => 0, size => 1024 },
);
__PACKAGE__->set_primary_key("sha1", "order");

=head1 RELATIONS

=head2 sha1

Type: belongs_to

Related object: L<MimeCas::Schema::Result::MimeObject>

=cut

__PACKAGE__->belongs_to(
  "sha1",
  "MimeCas::Schema::Result::MimeObject",
  { sha1 => "sha1" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-05-19 00:17:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BW8Q5C6LK3V/gLtxYP1i3Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
