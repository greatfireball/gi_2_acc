#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;

my $inputfile = "input.txt";
my $outputfile = "output.txt";

GetOptions(
    'i|in|inputfile=s' => \$inputfile,
    'o|out|outputfile=s' => \$outputfile
    );

my $infile; # variable to store the input filehandle

# check if the input file ist a compressed file
if ($inputfile =~ /\.gz|\.bz2/)
{
    require IO::Uncompress::AnyUncompress;
    $infile = new IO::Uncompress::AnyUncompress $inputfile || die "Unable to open input file '$inputfile': $!";
} else {
    open($infile, "<", $inputfile) || die "Unable to open input file '$inputfile': $!";
}

# generate a comma seperated list of gis
my $gilist;
while (<$infile>)
{
    chomp($_);

    # check if we have to add a ',' before adding a new gi
    if ($gilist)
    {
	$gilist .= ",";
    }

    # add the gi
    $gilist .= $_;
}

print $gilist;
