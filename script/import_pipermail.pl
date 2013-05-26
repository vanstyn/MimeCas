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

my $cleanup = 0;

my $tmp_file = '/tmp/import_pipermail.pl.tmp';
my $tmp_gz_file = $tmp_file . '.gz';
die "Temp file '$tmp_file' already exists\n" if (-e $tmp_file);
die "Temp gz file '$tmp_gz_file' already exists\n" if (-e $tmp_gz_file);

$cleanup = 1;

END {
  if($cleanup) {
    print "\n\nCleaning up temp files\n\n";
    unlink $tmp_file if (-f $tmp_file);
    unlink $tmp_gz_file if (-f $tmp_gz_file);
  }
}

my $url = $ARGV[0];
$url .= '/' unless ($url =~ /\/$/); # <-- ensure trailing slash
my $html = io($url)->slurp;

# Suck out all the link targets:
my @link_urls = ();
my $parser = HTML::TokeParser::Simple->new(\$html);
while (my $tag = $parser->get_tag) {
  push @link_urls, $tag->get_attr('href') if($tag->is_tag('a')); 
}

# Now get all the .txt.gz links and make them absolute
my @abs_gz_links = map { "$url$_"} grep { $_ =~ /\.txt\.gz$/ } @link_urls;

my $Rs = MimeCas->model('Schema::MimeObject');
my $i = 0;

foreach my $link (@abs_gz_links) {
  io($link) > io($tmp_gz_file);
  system('gunzip',$tmp_gz_file);
  
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
  
  print "\n";
  
  for my $msg (@messages) {
    my $MIME = Email::MIME->new($msg);
    $MIME->content_type_set( 'text/plain' ) unless ($MIME->content_type);
    
    print "\r  --> Importing message " . ++$i . " ($link)";
    try {
      $Rs->store_mime($MIME->as_string);
    }
    catch { warn "$_\n" };
  }
  
  unlink $tmp_file if (-f $tmp_file);
  unlink $tmp_gz_file if (-f $tmp_gz_file);
}

print "\n\n";


__END__




foreach my $link (@abs_gz_links) {
  io($link) > io($tmp_gz_file);
  system('gunzip',$tmp_gz_file);
  
  my $content = io($tmp_file)->slurp;
  my @messages = split(/-------------- next part --------------/,$content);
  
  for my $message (@messages) {
    
    # These things are freakin busted. wtf
    my $fixed = '';
    my $in_body = 0;
    my $in_header = 0;
    for my $line (split(/\r?\n/,$message)){
      unless ($in_header) {
        next if ($line =~ /^\s*$/);
        $in_header = 1;
      }
      if ($in_body) {
        $fixed .= "$line\n";
      }
      else {
        if ($line =~ /^\s*$/) {
          $in_body = 1;
          $fixed .= "\n";
          next;
        }
        # Check that this is a real header:
        my ($head,$value) = split(/\:/,$line,2);
        next unless ($head && $value); #<--- has a header/value
        next if ($head =~ /\s/); #<-- no spaces in header name
        $fixed .= "$line\n";
      }
    }
    
    my $MIME = Email::MIME->new($fixed);
    $MIME->content_type_set( 'text/plain' );
    
    print "\r  --> Importing message " . ++$i;
    try {
      $Rs->store_mime($MIME->as_string);
    }
    catch { warn "$_\n" };
  
  }
  
}




use Path::Class 0.32 qw( dir file );







my @files = ();
push @files, grep { -f $_ } glob($_) for (@ARGV);
my $tot = scalar(@files);
print "\n\n";

my $Rs = MimeCas->model('Schema::MimeObject');
my $i = 0;
foreach my $file (@files) {
  print "\r  --> Importing MIME file " . ++$i . " of $tot";
  try {
    my $content = file($file)->slurp;
    $Rs->store_mime($content);
  }
  catch { warn "$_\n" };
}

print "\n\n";


