package Schema::Result::MimeGraph;

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

Schema::Result::MimeGraph

=cut

__PACKAGE__->table("mime_graph");

=head1 ACCESSORS

=head2 child_sha1

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 40

=head2 parent_sha1

  data_type: 'char'
  is_nullable: 0
  size: 40

=head2 order

  data_type: 'tinyint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "child_sha1",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 40 },
  "parent_sha1",
  { data_type => "char", is_nullable => 0, size => 40 },
  "order",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("child_sha1", "parent_sha1");

=head1 RELATIONS

=head2 child_sha1

Type: belongs_to

Related object: L<Schema::Result::MimeObject>

=cut

__PACKAGE__->belongs_to(
  "child_sha1",
  "Schema::Result::MimeObject",
  { sha1 => "child_sha1" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 child_sha1

Type: belongs_to

Related object: L<Schema::Result::MimeObject>

=cut

__PACKAGE__->belongs_to(
  "child_sha1",
  "Schema::Result::MimeObject",
  { sha1 => "child_sha1" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-05-18 23:54:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:64MM4lX8h6WKa+nvIseh8w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
