package MimeCas::Schema::Result::MailMessage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("mail_message");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "folder_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "mailbox_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "uid",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "ordering",
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
__PACKAGE__->add_unique_constraint("folder_id", ["folder_id", "uid"]);
__PACKAGE__->belongs_to(
  "folder",
  "MimeCas::Schema::Result::MailFolder",
  { id => "folder_id" },
  { is_deferrable => 1, }, #on_delete => "CASCADE", on_update => "CASCADE" },
);
__PACKAGE__->belongs_to(
  "sha1",
  "MimeCas::Schema::Result::MimeObject",
  { sha1 => "sha1" },
  { is_deferrable => 1, }, #on_delete => "CASCADE", on_update => "CASCADE" },
);
__PACKAGE__->belongs_to(
  "mailbox",
  "MimeCas::Schema::Result::Mailbox",
  { id => "mailbox_id" },
  { is_deferrable => 1, }, #on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-05-30 13:56:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BL55PEsz/ovi68wHQ9+Y3A



sub insert {
  my $self = shift;
  $self->_set_extra_columns(@_);
  return $self->next::method;
}

sub update {
  my $self = shift;
  $self->_set_extra_columns(@_);
  return $self->next::method;
}

sub _set_extra_columns {
  my $self = shift;
  my $columns = shift;
	$self->set_inflated_columns($columns) if $columns;
  
  # Would rather not need the redundant column in the first place,
  # but it is needed for the relationship column
  $self->set_column( mailbox_id => $self->folder->get_column('mailbox_id') );
}


#__PACKAGE__->belongs_to(
#  "attribute",
#  "MimeCas::Schema::Result::MimeAttribute",
#  { sha1 => "sha1" },
#  { is_deferrable => 1, }, #on_delete => "CASCADE", on_update => "CASCADE" },
#);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
