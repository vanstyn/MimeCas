package MimeCas::Schema::Result::MailFolder;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("mail_folder");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "parent_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
  },
  "ordering",
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
__PACKAGE__->add_unique_constraint("mailbox_id", ["mailbox_id", "parent_id", "name"]);
__PACKAGE__->belongs_to(
  "parent",
  "MimeCas::Schema::Result::MailFolder",
  { id => "parent_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    #on_delete     => "CASCADE",
    #on_update     => "CASCADE",
  },
);
__PACKAGE__->has_many(
  "mail_folders",
  "MimeCas::Schema::Result::MailFolder",
  { "foreign.parent_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "mailbox",
  "MimeCas::Schema::Result::Mailbox",
  { id => "mailbox_id" },
  { is_deferrable => 1, }, #on_delete => "CASCADE", on_update => "CASCADE" },
);
__PACKAGE__->has_many(
  "mail_messages",
  "MimeCas::Schema::Result::MailMessage",
  { "foreign.folder_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-05-30 13:56:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JP24flfgFhDHHPjcVAxg7g

sub schema { (shift)->result_source->schema }

sub add_unique_message {
  my $self = shift;
  my $content = shift;
  
  my $MimeRow = $self->schema->resultset('MimeObject')->store_mime($content)
    or die "Error storing MIME Row";
  
  my $sha1 = $MimeRow->get_column('sha1');
  my $Rs = $self->mail_messages;
  return $Rs->search_rs({ sha1 => $sha1 })->first || $Rs->create({
    folder_id => $self->get_column('id'),
    sha1 => $sha1
  });
}





# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
