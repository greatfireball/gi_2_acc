#!/usr/bin/env perl

# the idea for that tool is based on the example code from NCBI:
# http://www.ncbi.nlm.nih.gov/books/NBK25498/#chapter3.Application_1_Converting_GI_num

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
my $max_ids_per_block = 500;

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
my $num_finished = 0;

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
	my $content = get($url);
	# check error and redo in this case for 5 times
	unless ($content)
	{
	    my $num_retries = 1;
	    my $wait_value = rand(30);
	    while($num_retries <= 5)
	    {
		printf STDERR "\rError during retrievment of accessions. Waiting for %d seconds and retrying for the %d time", $wait_value, $num_retries;
		sleep($wait_value);
		$content = get($url);
		last if ($content);

		$wait_value = rand(30);
		$num_retries++;
	    }
	    if ($num_retries > 5 && ! defined $content)
	    {
		die "Was not able to retrieve the following URL: '$url'";
	    }
	}
	my @accs = split(/\r*\n/, $content);

	# check if both lists have the same length
	if (@accs != @block)
	{
	    die "Different length of input and output list";
	}
	for(my $i=0; $i<@block; $i++)
	{
	    printf $outfile "%s\t%s\n", $block[$i], $accs[$i];
	}

	$num_finished += @block;

	printf STDERR "\rFinished % 7d sequences", $num_finished;

	@block = ();
    }
}

printf STDERR "\rFinished complete set with %d sequences\n", $num_finished;

close($outfile) || die "Unable to close the output file '$outputfile': $!";

