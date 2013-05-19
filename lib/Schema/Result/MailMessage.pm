package Schema::Result::MailMessage;

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

Schema::Result::MailMessage

=cut

__PACKAGE__->table("mail_message");

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
  is_nullable: 0

=head2 order

  data_type: 'tinyint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 sha1

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 40

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
    is_nullable => 0,
  },
  "order",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "sha1",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 40 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 pid

Type: belongs_to

Related object: L<Schema::Result::MailFolder>

=cut

__PACKAGE__->belongs_to(
  "pid",
  "Schema::Result::MailFolder",
  { id => "pid" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aZY05YrVZ9+lZGyHLL0yOQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
