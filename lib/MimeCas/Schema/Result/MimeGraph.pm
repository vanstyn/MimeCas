package MimeCas::Schema::Result::MimeGraph;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("mime_graph");
__PACKAGE__->add_columns(
  "child_sha1",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 40 },
  "parent_sha1",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 40 },
  "ordering",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("child_sha1", "parent_sha1");
__PACKAGE__->belongs_to(
  "child_sha1",
  "MimeCas::Schema::Result::MimeObject",
  { sha1 => "child_sha1" },
  { is_deferrable => 1, }, #on_delete => "CASCADE", on_update => "CASCADE" },
);
__PACKAGE__->belongs_to(
  "parent_sha1",
  "MimeCas::Schema::Result::MimeObject",
  { sha1 => "parent_sha1" },
  { is_deferrable => 1, }, #on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-05-30 13:56:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lMt1jb4WkEr1kzLp9Pne7A

__PACKAGE__->belongs_to(
  "child_object",
  "MimeCas::Schema::Result::MimeObject",
  { sha1 => "child_sha1" },
  { is_deferrable => 1, }, #on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->belongs_to(
  "parent_object",
  "MimeCas::Schema::Result::MimeObject",
  { sha1 => "parent_sha1" },
  { is_deferrable => 1, }, #on_delete => "CASCADE", on_update => "CASCADE" },
);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
