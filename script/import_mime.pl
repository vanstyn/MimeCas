#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use MimeCas;

use Path::Class 0.32 qw( dir file );
my $content = file($ARGV[0])->slurp;

my $Rs = MimeCas->model('Schema::MimeObject');

print "\n\n ---- Importing MIME from file ----\n\n";
$Rs->store_mime($content);

