package Chrisbot::Pipeline;

# Copyright (c) 2003 Chris Angell (chris62vw@hotmail.com). All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

# IRC Bot version 0.3

# handles input

use strict;
use warnings;
no warnings 'uninitialized';
use URI::Escape;
use List::Util;

sub spoken_to
{

	my ($self)	= @_;
	local $_	= $self->get("query");
	my ($who, $chan, $whisper) = $self->get(qw/user_nick chan whisper/);

	print STDERR "SOKEN_TO: <$who/$chan> $whisper :: $_\n";

	s/^[\-\+]//;

	# study $_
	study;
	
	# say hi
	if ( /^(hi|hello|hey|yo|sup|hiya)\s*$/i )
	{

		$self->act( SAY => $chan, "$1 $who" . $self->get("punctuation") );

	}
	# tell someone something (in Chrisbot::Common)
	elsif ( /^tell\s+(\S+)\s+(?:about|to)\s+(.+?)\s*$/i )
	{

		$self->tell( $1, $who, $chan, $2 );

	}
	# tell someone something - different syntax: botname: fact > user
	elsif ( /^(.+?)\s*>\s*(\S+)\s*$/i && length $self->fact(GET => $1) )
	{

		$self->tell( $2, $who, $chan, $1 );

	}
	# math expressions (in Chrisbot::Common)
	elsif ( /^(?:math|calc)\s+(.+?)\s*$/i )
	{

		$self->act( SAY => $chan, $self->math($1) );

	}
	# geoip
	elsif ( /^geo\s*ip\s+(\S+)\s*$/i )
	{

		$self->act( SAY => $chan, $self->geoip($1) );

	}
	# host utility (in Chrisbot::Common)
	elsif ( /^host\s+(?:-t\s+)?(\S+)\s+(.+?)\s*$/i )
	{
		
		# $1 is the query type, $2 is the host/addr/data
		$self->act( SAY => $chan, $self->host($1, $2));

	}
	# dns - a shortcut
	elsif ( /^dns\s+(.+?)\s*$/i )
	{
		
		# $1 is the query type, $2 is the host/addr/data
		$self->act( SAY => $chan, $self->host(A => $1));

	}
	# roll a die or dice (in Chrisbot::Common)
	elsif ( /^(?:roll|dice)\s+(\d{1,5})?d(\d{1,5})\s*$/i )
	{

		$self->act( SAY => $chan, $self->roll(($1||1), $2));

	}
	# temperature conversion (in Chrisbot::Common)
	elsif ( /^temp(?:\s+)?conv\s+(.+?)\s*$/i )
	{

		$self->act( SAY => $chan, $self->tempconv($1) );

	}
	# scramble text (in Chrisbot::Common)
	elsif ( /^scramble\s+(.+?)\s*$/i )
	{

		$self->act( SAY => $chan, $self->scramble($1) );

	}
	# reverse phone number lookup
	elsif ( /^phone\s*(?:-?lookup)?\s+(.+?)\s*$/i )
	{

		$self->act( SAY => $chan, $self->revlookup($1) );

	}
	elsif ( /^(?:utf8|unicode)\s+(.+?)\s*$/i )
	{

		$self->act( SAY => $chan, $self->unicode($1) );

	}
	# reverse text
	elsif ( /^reverse\s+(.+?)\s*$/i )
	{

		$self->act( SAY => $chan, scalar reverse $1 );

	}
	# length of string
	elsif ( /^length\s+(.+)$/i )
	{

		$self->act( SAY => $chan, length $1 );

	}
	# time
	elsif ( /^what\s+time(?:\s+i[st]\s+i[st])?\s*$/i )
	{

		$self->act( SAY => $chan, scalar(localtime) . " Pacific Time" );

	}
	# 8ball (in Chrisbot::Common)
	elsif ( /^(?:magic)?\s*8[ -]?ball\s*/i )
	{

		$self->act( SAY => $chan, $self->magic8ball );

	}
	# shorten last uri seen in channel
	elsif ( /^shorten\s+(?:it|(?:last(?:\s+ur[il])?))\s*$/i )
	{

		if (my $url = $self->chan_url( GET => $chan ))
		{

			$self->act( SAY => $chan, "Shortened URL: " . $self->shorten_url($url) );

		}
		else
		{
			$self->act( SAY => $chan, "$who, I haven't seen a URL in $chan yet." );
		}

	}
	# shorten a url
	elsif ( /^shorten\s+(.+?)\s*$/i )
	{

		$self->act( SAY => $chan, "Shortened URL: " . $self->shorten_url($1) );

	}
	# rot13
	elsif ( /^rot\s*13\s+(.+?)\s*$/i )
	{

		my $rot_str = $1;
		$rot_str =~ y/a-zA-Z/n-za-mN-ZA-M/;

		$self->act( SAY => $chan, $rot_str );
		
	}
	# fortune
	elsif ( /^fortune\s*$/i )
	{

		$self->act( SAY => $chan, $self->fortune );

	}
	# google
	elsif ( /^google\s+for\s+(.+?)\s*$/i )
	{

		$self->act( SAY => $chan, "oblio: google for $1" );

	}
	# tell a user what channel he is in
	elsif ( /^where\s+am\s+I$/i )
	{

		my $msg = $self->get("whisper") ? "I don't know; this is a private message" : "$who, you are in $chan";
		$self->act( SAY => $chan, $msg );

	}
	# repeat something
	elsif ( /^repeat\s+(.+)$/i )
	{

		$self->act( SAY => $chan, $1 );

	}
	# act stupid
	elsif ( /^be\s+(?:a\s+)?retard(?:ed|o)?\s*$/i )
	{

		$self->act( SAY => $chan, $self->retard );

	}
	# act like someone stupid
	elsif ( /^(?:act|be)\s+(?:like\s+)?(.+?)\s*$/i )
	{

		my $be_who = $1;
		
		if (lc $be_who eq "friedo")
		{
			
			$self->act( ACTION => $chan, "kicks $who in the balls" );
			
		}
		else
		{

			$self->act( SAY => $chan, $self->retard($be_who) );

		}
			
	}
	# flip a coin
	elsif ( /^flip(?:\s+a\s+coin)?\s*$/i )
	{
	
		my $result;
		
		if (rand 100 > 99)
		{

			$result = "The coin landed on its side!";

		}
		else
		{

			$result = [qw/heads tails/]->[rand 2];

		}
		
		$self->act( SAY => $chan, $result );

	}
	# get karma for something
	elsif ( /^(?:karma|score)(?:\s+(?:for|of))?\s+(.+?)\s*$/i )
	{

		my $karma_val = $self->karma( GET => $1 );

		my $karma_msg = $karma_val
			? "Karma for $1: $karma_val"
			: "$1 doesn't have any karma";
		
		$self->act( SAY => $chan, $karma_msg );

	}
	# top N karma entries
	elsif ( /^(?:top|highest)\s+(?:(\d+)\s+)?karmas?\s*$/i )
	{

		my $num = $1 || 5;
		
		# limit to 20 entries max
		if ($num > 20)
		{

			$self->act( SAY => $chan, "Sorry, $num is too many results.  Try a number less than 21" );

		}
		else
		{

			my $results = join ", ", $self->karma( TOP_N => $num );

			$self->act( SAY => $chan, "The top $num karma entries: $results" );

		}
		
	}
	# bottom N karma entries
	elsif ( /^(?:bottom|lowest|last)\s+(?:(\d+)\s+)?karmas?\s*$/i )
	{

		my $num = $1 || 5;
		
		# limit to 20 entries max
		if ($num > 20)
		{

			$self->act( SAY => $chan, "Sorry, $num is too many results.  Try a number less than 21" );

		}
		else
		{

			my $results = join ", ", $self->karma( BOTTOM_N => $num );

			$self->act( SAY => $chan, "The bottom $num karma entries: $results" );

		}
		
	}
	# perldoc -f func
	elsif ( /^(?:perldoc\s+)?-f\s+(\S+)\s*$/i )
	{
		
		$self->act( SAY => $chan, $self->fetch_func_url($1) );

	}
	# cpan modules
	elsif ( /^(?:perldoc|documentation|docs?|cpan|url)\s+(?:(?:about|for|of|on)\s+)?(.+?)\s*$/i )
	{

		my $url = "http://search.cpan.org/perldoc/";
	   	$url .= uri_escape($1);
		my $short_url = $self->shorten_url($url);
		$self->act( SAY => $chan, "Documentation for '$1' can be found here: " . $short_url );

	}
	# cpan search
	elsif ( /^(?:search\s+)?cpan\s+(?:for\s+)?(.+?)\s*$/i )
	{

		my $url = $self->bot_cfg("CPAN_SEARCH_URL");
		$url .= uri_escape($1);
		my $short_url = $self->shorten_url($url);
		$self->act( SAY => $chan, "Search results for '$1' can be found here: " . $short_url );

	}
	# unf someone
	elsif ( /^(?:sex|rape|fist)\s+(.+?)\s*$/i )
	{

		$self->act( ACTION => $chan, "rapes $1 with a broomstick" );

	}
	# lick
	elsif ( /^(?:lick)\s+(.+?)\s*$/i )
	{

		$self->act( ACTION => $chan, "licks $1" );

	}
	# jargon file
	elsif ( /^jargon\s+(?:entry\s+)?(?:for\s+)?(.+?)\s*$/i )
	{

		my $def = $self->jargon($1);
		$self->act( SAY => $chan, $def );

	}
	# slap
	elsif ( /^slap\s+(\S+)(\s+\S.+?)?\s*$/i )
	{

		my $slap = "slaps $1";
		$slap   .= $2 ? $2 : " around a bit with a large trout";
		$self->act( ACTION => $chan, $slap );

	}
	# make fun of someone
	elsif ( /^diss\s+(.+?)\s*$/i )
	{

		my $diss = [ "$1 is a lamer!", "OMG $1 sucks.", "I 0wn j00 $1.", "$1 is my little bitch." ];
		$self->act( SAY => $chan, $diss->[rand 4] );
		
	}
	# lart
	elsif ( /^lart\s+(.+?)\s*$/i )
	{

		$self->act( ACTION => $chan, "lowers $1's disk quota to 10kb" );
				
	}
	# talk
	elsif ( /^(?:say|talk)\s+(?:in|to)\s+([#&]?\S+)\s+(.+?)\s*$/i )
	{

		# access check
		my $qualified_user = $self->get("user_mask") eq "p3m/member/simcop2387";

		if ($qualified_user)
		{

			$self->act( SAY => $1, $2 . $self->get("punctuation") );
		
		}
		else
		{
			
			$self->act( SAY => $chan, "Sorry, you're not special enough to do that");
		
		}

	}
	# act
	elsif ( /^(?:action)\s+(?:in|to)\s+([#&]?\S+)\s+(.+?)\s*$/i )
	{

		# access check
		my $qualified_user = $self->get("user_mask") eq "p3m/member/simcop2387";

		if ($qualified_user)
		{

			$self->act( ACTION => $1, $2 );
		
		}
		else
		{
			
			$self->act( SAY => $chan, "Sorry, you're not special enough to do that");
		
		}

	}
	# login with newdlebot (#idlerpg)
	elsif ( /^regidle\s*$/i )
	{

		# access check
		my $qualified_user = $self->get("user_mask") eq "p3m/member/simcop2387";

		if ($qualified_user)
		{

			$self->act( SAY => "NewdleBot", "LOGIN perlbot falafel" );
			$self->act( SAY => $chan, "Done." );
		
		}
		else
		{
			
			$self->act( SAY => $chan, "Sorry, you're not special enough to do that");
		
		}

	}
	# perldoc -q term
	elsif (/^(?:perldoc\s*)?-q\s+(.+?)\s*$/i )
	{

		$self->act( SAY => $chan, $self->perldoc_q($1) );

	}
    # forget fact
	elsif ( /^forget\s+(.+?)\s*$/i )
	{

		my $return = $self->fact( REMOVE => $1 . $self->get("punctuation"));
		$self->act( SAY => $chan, $self->get("FACT_MSG") );
		
	}
    # overwrite fact
	elsif ( /^(?:no(?:\s*,)?|overwrite|re-?learn|redefine)\s+(.+?)\s+[ia]s\s+(.+?)\s*$/i )
	{

		# remove fact if it exists
		my $fact_existed = $self->fact( REMOVE => $1);

		# now add the new fact
		my $fact = $2 . $self->get("punctuation");
		my $return = $self->fact( ADD => $1, $fact );
		my $msg = $fact_existed
			? "relearned entry for $1"
			: "there was no entry for $1, so I added it to the database";
		$self->act( SAY => $chan, $msg );

	}
	# learn fact
	elsif ( /^(?:learn|add|remember)\s+(.+?)\s+[ia]s\s+(.+?)\s*$/i || /^(.+?)\s+is\s+(.+?)\s*$/i )
	{

		my $fact= $2 . $self->get("punctuation");
		my $return = $self->fact( ADD => $1, $fact );
		my $msg = $return ? $self->get("FACT_MSG") : $self->get("FACT_MSG");
		$self->act( SAY => $chan, $msg );

	}
	# search fact values, return keys whose values contain search term
	elsif ( /^(?:fact-?)?search\s+(?:for\s+)?(.+?)\s*$/i )
	{

		my @results = map { @$_ } @{ $self->fact( SEARCH => $1 ) };
		
		
		if (@results)
		{
		
			my $msg;
			my $num_res = @results;

	
			if ($num_res == 1)
			{

				$msg = "One match for \"$1\": ";

			}
			elsif ($num_res > 25)
			{

				@results = (List::Util::shuffle(@results))[0..24];
				$msg = "Random 25 matches (out of $num_res) for \"$1\": ";

			}
			else
			{

				$msg = "Found $num_res matches for \"$1\": ";

			}
			
			$self->act( SAY => $chan, $msg . join ", ", @results );

		 }
		 else
		 {

			 $self->act( SAY => $chan, "Sorry, no factoids contain the string \"$1\"" );

		 }

	}
	# add a user to the user access system
#	# (username, level, hostmask, password, email)
#	elsif ( /^adduser\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s*$/i )
#	{
#
#		$self->act( SAY => $chan, "Sorry, your access level doesn't allow you to do that." ), return
#			unless $self->user_access( GET_USER_DATA => $who, "level" ) >= 4;
#		
#		my $msg = $self->user_access( ADD_USER => $1, $2, $3, $4, $5 );
#		$self->act( SAY => $chan, $msg );
#		
#	}
#	# get information about a user that is in the user database
#	elsif ( /^user\s*info\s+(\S+)\s*$/i )
#	{
#
#		my $user = $1;
#		
#		# get user data
#		my %data = $self->user_access( GET_USER_DATA => $user );
#
#		# make sure user exists
#		$self->act( SAY => $chan, "No such user $user" ), return unless defined $data{username};
#
#		# user requesting information must be at a higher level than
#		# the user who gets the information...
#		my $user_level = $data{level};
#
#		# ...except operators and owners can look at all levels
#		$user_level = 0
#			if  ($self->user_access( CHECK_MASK => $who))
#			and ($self->user_access( GET_USER_DATA => $who, "level" ) >= 3);
#
#		my $msg;
#
#		if ($self->user_access( VALIDATE => $who, $user_level))
#		{
#
#			$msg = "Username: $data{username}  Access Level: $data{level}  Hostmask: $data{hostmask}  Email: $data{email}";
#
#		}
#		else
#		{
#	
#			$msg = 	"Sorry, your access level doesn't allow you to do that.";
#
#		}
#		
#		$self->act( SAY => $chan, $msg );
#		
#	}
	# explicitly check a keyword
	elsif ( /^keyword\s+(.+?)\s*$/i )
	{

		my $fact = $self->fact( GET => $1 ); 
		my $msg = defined $fact ? $fact : "$1 isn't a keyword.  It could be one of my builtin functions, or it could be nothing.";
		$self->act( SAY => $chan, "Information for keyword \"$1\": $msg" );
		
	}
        elsif (/^eval:?\s*(.*)/i)
        {
          $self->act(SAY => $chan, $self->eval($1));
        }
	# everything else gets compared against the factoid database
	else
	{

		if (defined( my $fact = $self->fact( GET => $_ )))
		{

			# turns %NICK% into $who
			$fact =~ s/\%nick\%/$who/gi;
			
			$self->act( SAY => $chan, $fact )

		}

	}

}


sub not_spoken_to
{

	# uncomment code when there is a reason to

	# my $self = shift;

	# local $_    = $self->get("LINE");
	# my $me      = $self->bot_cfg("NICK");
	# my ($who, $chan, $whisper) = $self->get(qw/user_nick chan whisper/);

}


1;
