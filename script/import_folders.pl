#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

$| = 1;
use Try::Tiny;

use Path::Class 0.32 qw( dir file );
use Getopt::Long;

use MimeCas;
my $Rs = MimeCas->model('Schema::Mailbox');
my $MimeRs = MimeCas->model('Schema::MimeObject');

my ($mailbox_name,$root_folder);
GetOptions(
  'mailbox_name=s' => \$mailbox_name,
  'root_folder=s' => \$root_folder,
);

die "--mailbox_name required\n" unless ($mailbox_name);
die "--root_folder required\n" unless ($root_folder);
die "'$root_folder' is not a directory\n" unless (-d $root_folder);

my $Mailbox = 
  $Rs->search_rs({ name => $mailbox_name })->first ||
  $Rs->create({ name => $mailbox_name });

my $i = 0;

our $parent = {};
sub process_dir {
  my $dir = shift;
  
  print "Processing $dir\n";
  
  my $name = $parent->{dir} ? $dir->relative($parent->{dir}) : '/';
  
  my $create = { 
    name => $name,
    mailbox_id => $Mailbox->get_column('id')
  };
  $create->{parent_id} = $parent->{folder_row}->get_column('id')
    if ($parent->{folder_row});
  
  my $Folder = 
    $Mailbox->mail_folders->search_rs($create)->first ||
    $Mailbox->mail_folders->create($create);

  for my $child ($dir->children) {
    if($child->is_dir) {
      local $parent = {
        dir => $dir,
        folder_row => $Folder
      };
      &process_dir($child);
    }
    else {
      print "\r  --> Importing MIME file " . ++$i . " ($child)";
      try {
        my $content = $child->slurp;
        my $MimeRow = $MimeRs->store_mime($content);
        
        $Folder->mail_messages->update_or_create({
          uid => $child->relative($dir),
          folder_id => $Folder->get_column('id'),
          sha1 => $MimeRow->get_column('sha1')
        },{ key => 'folder_id' });
      }
      catch { warn "$_\n" };
    }
  }
  
  print "\n";
}

process_dir( dir($root_folder) );

