#!/usr/bin/perl

# QUICK/DIRTY script
# Imports directly from a pipermail (Mailman) archive URL
# NOTE: expects the very specific markup as found on a pipermail
# Archive page

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

$| = 1;
use Try::Tiny;

require IO::All::LWP;
use IO::All;
use HTML::TokeParser::Simple;
use Email::MIME;
use List::Util qw(reduce);

use MimeCas;
use Getopt::Long;
my $Rs = MimeCas->model('Schema::Mailbox');
my $MimeRs = MimeCas->model('Schema::MimeObject');

my ($urls,$folder_regex,$clear_folder,$clear_mailbox);
GetOptions(
  # comma sep list of pipermail archive urls
  'urls=s' => \$urls,
  
  # Regex to match to include a folder (applied to month filename)
  'folder_regex=s' => \$folder_regex,
  
  # Whether or not to clear existing folder
  'clear_folder+' => \$clear_folder,
  
  # Whether or not to clear existing mailbox
  'clear_mailbox+' => \$clear_mailbox
);
die "--urls required\n" unless ($urls);
my @urls = split(/\,/,$urls);

if($folder_regex) {
  $folder_regex =~ s/^\///;
  $folder_regex =~ s/\/$//;
}

my $cleanup = 0;

my $tmp_file = '/tmp/import_pipermail_folders.pl.tmp';
my $tmp_gz_file = $tmp_file . '.gz';
die "Temp file '$tmp_file' already exists\n" if (-e $tmp_file);
die "Temp gz file '$tmp_gz_file' already exists\n" if (-e $tmp_gz_file);

$cleanup = 1;

$SIG{INT} = sub { exit; };

END {
  if($cleanup) {
    print "\n\nCleaning up temp files\n\n";
    unlink $tmp_file if (-f $tmp_file);
    unlink $tmp_gz_file if (-f $tmp_gz_file);
  }
}


sub get_link_name {
  my $link = shift;
  $link =~ s/\/$//;
  my @parts = split(/\//,$link);
  return pop @parts;
}



sub extract_link_messages {
  my $link = shift;
  
  if ($link =~ /\.gz$/) {
    io($link) > io($tmp_gz_file);
    system('gunzip',$tmp_gz_file);
  }
  else {
    io($link) > io($tmp_file);
  }
  
  my $idx = 0;
  my @messages;
  
  # Ugly, lame format. Horrible to figure out where one message ends 
  # and the next begins. Need to compare 2 lines at once and this could
  # easlily be injected. This is retarted
  my $last_line;
  reduce {
    $messages[$idx] //= '';
    
    if($a =~ /^From/ && $b =~ /From\:/) {
      # We're on the first line of a new message:
      $idx++;
    }
    else {
      # Write the line from the *previous* call
      $messages[$idx] .= $a;
    }
    $last_line = "$b";
    
    $b; # <-- $b becomes $a for the next call...
  } io($tmp_file)->getlines;
  # The very last line won't get called above:
  $messages[$idx] .= $last_line;
  
  unlink $tmp_file if (-f $tmp_file);
  unlink $tmp_gz_file if (-f $tmp_gz_file);
  
  return @messages;
}

sub process_archive_url {
  my $url = shift;

  my $mailbox_name = get_link_name($url);

  $url .= '/' unless ($url =~ /\/$/); # <-- ensure trailing slash
  my $html = io($url)->slurp;

  my $Mailbox = 
    $Rs->search_rs({ name => $mailbox_name })->first ||
    $Rs->create({ name => $mailbox_name });
    
  if($clear_mailbox) {
    $Mailbox->mail_messages->delete;
    $Mailbox->mail_folders->delete;
  }

  # Suck out all the link targets:
  my @link_urls = ();
  my $parser = HTML::TokeParser::Simple->new(\$html);
  while (my $tag = $parser->get_tag) {
    push @link_urls, $tag->get_attr('href') if($tag->is_tag('a')); 
  }

  # Now get all the .txt.gz or .txt links and make them absolute
  my @abs_links = map { "$url$_"} grep { 
    $_ =~ /\.txt\.gz$/ ||
    $_ =~ /\.txt$/
  } @link_urls;

  foreach my $link (@abs_links) {
    
    my @messages = extract_link_messages($link);
    my $folder_name = get_link_name($link);
    if($folder_regex) {
      next unless (eval '$folder_name =~ /' . $folder_regex . '/');
    }
    
    print "Processing $folder_name\n";
    
    my $create = { 
      name => $folder_name,
      mailbox_id => $Mailbox->get_column('id')
    };
    
    my $Folder = 
      $Mailbox->mail_folders->search_rs($create)->first ||
      $Mailbox->mail_folders->create($create);
      
    $Folder->mail_messages->delete if ($clear_folder);
    
    my $i = 0;
    for my $msg (@messages) {
      my $MIME = Email::MIME->new($msg);
      $MIME->content_type_set( 'text/plain' ) unless ($MIME->content_type);
      
      print "\r  --> Importing message " . ++$i . " ($link)";
      try {
        my $content = $MIME->as_string;
        my $MimeRow = $MimeRs->store_mime($content);
        
        $Folder->mail_messages->update_or_create({
          uid => $i,
          folder_id => $Folder->get_column('id'),
          sha1 => $MimeRow->get_column('sha1')
        },{ key => 'folder_id' });
      }
      catch { warn "$_\n" };
    }
    
    print "\n";
  }

  print "\n\n";
}



process_archive_url($_) for (@urls);

