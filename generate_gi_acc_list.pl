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

# I want to work on blocks of maximum $max_ids_per_block gis
my $max_ids_per_block = 1000;

# generate a comma seperated list of gis
my $gilist;
my @block = ();
while (<$infile>)
{
    chomp($_);

    push(@block, $_+0);

    if (@block >= $max_ids_per_block || eof($infile))
    {
	my $gilist = join(",", @block);
	print $gilist;

	@block = ();
    }
}

