#!/usr/bin/perl -wl

use strict;
use warnings;
use Safe;

$ARGV[0] or die "usage: $0 \"math expr\"";

print math($ARGV[0]);

sub math
{ 

	my ($expr) = @_;
	
	# reject right away before the expression even gets to Safe
	return "acceptable operators, variables, and grouping characters are + - * / ** ^ % ( )" if tainted($expr);

	# perl uses ** for exponents
	$expr =~ s(\^)(**)g;

	# don't let perl's vstrings ruin the expression.  I, for one, can't wait until vstrings are gone from Perl!
	return "Part of the expression will evaluate using Perl's v-strings.  Try again without attempting to use v-strings." if $expr =~ /\.\d+\./;
	
	# create a "safe compartment"
	my $safe = Safe->new;

	# only the following opcodes will be permitted
	$safe->permit_only(qw(leaveeval entereval const
			add subtract multiply divide modulo pow));
	
	# eval $expr in the safe compartment
	my $result = $safe->reval($expr);

	# was there an error?  If so, rip out the relevant error
	# message and return it.  Otherwise, return the result of the
	# eval
	if (my ($err_msg) = $@ =~ /^(.+) at \(eval \d+\) line \d+\.$/)
	{
		
		return "Bad Expression: $err_msg";

	}
	else
	{

		return $result;

	}
	
}

sub tainted
{

	# return false if there are any unallowable characters in the string
	return $_[0] =~ /[^\d%+.*\/^)( -]/;	

}
