#!/usr/bin/env perl

use strict;
use warnings;

use LWP::Simple;

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

# prepare the output file
my $outfile;
if ($outputfile ne "-")
{
    open($outfile, ">", $outputfile) || die "Unable to open input file '$inputfile': $!";
} else {
    $outfile = \*STDOUT;
}

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

	#assemble the URL
	my $base = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/';
	my $url = $base . "efetch.fcgi?db=nucleotide&id=$gilist&rettype=acc";

	#post the URL
	my @accs = split(/\r*\n/, get($url));

	# check if both lists have the same length
	if (@accs != @block)
	{
	    die "Different length of input and output list";
	}
	for(my $i=0; $i<@block; $i++)
	{
	    printf $outfile "%s\t%s\n", $block[$i], $accs[$i];
	}

	@block = ();
    }
}

close($outfile) || die "Unable to close the output file '$outputfile': $!";

