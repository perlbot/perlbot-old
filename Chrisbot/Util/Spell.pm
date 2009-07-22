package Chrisbot::Util::Spell;

# Copyright (c) 2006 Chris Angell (chris62vw@hotmail.com). All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

# correct spelling

use strict;
use warnings;

use Text::Aspell;
	
my $speller = Text::Aspell->new;
$speller->set_option(lang => "en_US");

sub spell {

	if ($speller->check($word))
	{
		
		return $word;

	}
	else
	{
		my @suggestions = $speller->suggest($word);
		
		return @suggestions
			? "Couldn't find $word in the dictionary; maybe you meant one of these: @suggestions"
			: "Couldn't find $word in the dictionary, and there are no suggestions for that word.";
	
	}

}

1;
