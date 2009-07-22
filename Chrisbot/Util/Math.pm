package Chrisbot::Util::Math;

# Copyright (c) 2003 Chris Angell (chris62vw@hotmail.com). All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

# IRC Bot version 0.3

# evaluates math expressions

use strict;
use warnings;
use Safe;

sub new 
{ 

	my ($self, $expr) = @_;
	
	# return "acceptable operators, grouping characters, and other characters are + - * / ** ^ % ( ) _ x a-z" if tainted($expr);

	# can't start with a /
	return "Bad Expression: can't start with /" if "/" eq substr $expr, 0, 1;
	
	# perl uses ** for exponents
	$expr =~ s(\^)(**)g;

	# pie
	$expr =~ s/\bpi\b/3.141592653589/ig;
	
	# e
	$expr =~ s/\be\b/2.718281828459/ig;
	
	# don't let perl's vstrings ruin the expression
	return "Part of the expression will evaluate using Perl's v-strings.  Try again without attempting to use v-strings." if $expr =~ /\.\d+\./;

	# create a "safe compartment"
	my $safe = Safe->new;

	# only the following opcodes will be permitted
	$safe->permit_only(qw(
		padany lineseq
		leaveeval entereval const negate
		add subtract multiply divide modulo pow
		preinc postinc predec postdec abs
		abs atan2 cos exp hex int log oct rand sin sqrt
		pushmark list
		));

	# some functions use $_ if no argument is specified, so might as well make sure $_ is empty
	local $_;
	
	# eval $expr in the safe compartment
	my $result = $safe->reval($expr);
	
	# was there an error?  If so, rip out the relevant error message
	# and return it.  Otherwise, return the result of the eval
	if (my ($err_msg) = $@ =~ /^(.+) at \(eval \d+\) line \d+/)
	{

		return "Bad Expression: $err_msg";
		
	}
	else
	{

		return $result;

	}

}

1;
