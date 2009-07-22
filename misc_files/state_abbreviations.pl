#!/usr/bin/perl -w

use strict;

open my $fh, "state_abbreviations.txt" or die "open: $!";

while (<$fh>)
{

	chomp;
	my ($abbrev, $full) = split /=/;
	print ".$abbrev.us is $full\n";
	
}
