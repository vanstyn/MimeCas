#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

$| = 1;
use Try::Tiny;

use MimeCas;
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


