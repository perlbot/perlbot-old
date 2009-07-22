package Chrisbot::Parser;

# Copyright (c) 2003 Chris Angell (chris62vw@hotmail.com). All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

# IRC Bot version 0.3

# parses input

use strict;
use warnings;

our $PONGTO = "";

sub parse
{

	# first pass
	# determine whether the line is a privmsg, or a system
	# message, and deal with accordingly

	# this method is called every time the bot sees a line of text/data
	# so make it clean and efficient
	
	my ($self, $line) = @_;

	# get rid of \r at end and/or get rid of newlines if they are there
	$line =~ tr/\r\n//d;

	$self->set(LINE => $line);
	
	# are we dealing with a privmsg (channel message or msg from user) ?
	# if so, call priv msg handling routine
	# if not, send to routine that handles non-chat

	if ($line =~ /^:\S+\s+PRIVMSG\s+/)
	{
		
		_msg_handler($self, $line);

	}
	else
	{

		_sys_handler($self, $line);

	}

	# this would be a good place to log data
	
}


sub _sys_handler
{

	# handle non-chat like server to client ping, etc.

	(my $self, local $_) = @_;

	# remove character that lets people do ACTIONs and the like
	tr/\001//d;

	my $nick = $self->bot_cfg("NICK");
	#print STDERR "PARSER: $nick\n";

	# Messages that can be ignored
	# this is incomplete but better than nothing - I am too lazy to figure out all codes
	return if /^:\S+\s+(?:37[256]|25[1235]|353|366|00[234]|NOTICE) /i;

	# Server to client ping
	if(/^ping :(\S+)/i)
	{
		$PONGTO = $1;
		return $self->act( PONG => $1 );
	}

	# restart bot if an error occurs
	$self->restart_bot("IRCD ERROR: $1") if /^ERROR :(.+?)\s*$/i;
	
	# Nick is already in use
	if (/^:\S+ 433 /)
	{

		# change Chrisbot to tChrisbo, tChrisbo to otChrisb, etc.
		# isn't completely fool-proof but should do the job
		$nick =~ s/(.+)(.)$/$2$1/;
		return $self->act( SET_NICK => $nick );

	}

	# Automatically rejoin if kicked
	return $self->act( JOIN_CHAN => $1 ) if /^:\S+ KICK (\S+) $nick :/i and lc $self->bot_cfg("AUTO_REJOIN") eq "yes";

}


sub _msg_handler
{

	(my($self), local($_)) = @_;

	# ignore "actions"
	return if tr/\001//d;
	# respond to CTCP queries
	
	# CTCP Ping
	return $self->act( CTCP_PING => $1, $2 )
	    if /^:([^!]+)!\S+ PRIVMSG [#&]?\S+ :\x01PING\s*(.*?)\s*\x01$/i;
	
	# CTCP Version
	return $self->act( CTCP_VERSION => $1 )
		if /^:([^!]+)!\S+ PRIVMSG [#&]?\S+ :\x01VERSION\s?\x01$/i;

	# CTCP Time
	return $self->act( CTCP_TIME => $1 )
		if /^:([^!]+)!\S+ PRIVMSG [#&]?\S+ :\x01TIME\s?\x01$/i;
	
	# now that CTCP's are done, remove character that lets people do ACTIONs and the like
	tr/\001//d;

	# set configuration data for this line of input
	# i.e. who talked to the bot, the channel, etc.

	# are we being spoken to in a channel, or via priv chat?

	# :tybalt89!rick@adsl-63-198-216-176.dsl.snfc21.pacbell.net PRIVMSG #modperl :ouch!
	# :Chris61vw!~chris62vw@chris.a1-office.biz PRIVMSG perlbot :this is a private message

	my $my_nick			= $self->bot_cfg("NICK");
	my $my_nick_nonum		= $my_nick;
	$my_nick_nonum =~ s/\d+$//;

	print STDERR "PARSER: $my_nick :: $my_nick_nonum || $_\n";

#	my $WHISPERED_TO	= qr/^:([^!]+)!(\S+)@(\S+) PRIVMSG [^#& ]+ :\s*(.+?)\s*([.?!]*)\s*$/;
#	my $SPOKEN_TO_1		= qr/^:([^!]+)!(\S+)@(\S+) PRIVMSG ([#&]\S+) :\s*$my_nick(?:[,:]|\s+)\s*(.*?)\s*([.?!]*)\s*$/i;	# "$nick, hello" spoken directly to
#	my $SPOKEN_TO_2		= qr/^:([^!]+)!(\S+)@(\S+) PRIVMSG ([#&]\S+) :\s*(.+?)\s*,?\s*$my_nick\s*([.?!]*)\s*$/i;	# "hello $nick"  - indirect
#	my $SPOKEN_TO_3		= qr/^:([^!]+)!(\S+)@(\S+) PRIVMSG ([#&]\S+) :\s*$my_nick_nonum(?:[,:]|\s+)\s*(.*?)\s*([.?!]*)\s*$/i;	# "$nick, hello" spoken directly to
#	my $SPOKEN_TO_4		= qr/^:([^!]+)!(\S+)@(\S+) PRIVMSG ([#&]\S+) :\s*(.+?)\s*,?\s*$my_nick_nonum\s*([.?!]*)\s*$/i;	# "hello $nick"  - indirect
#	my $NOT_SPOKEN_TO	= qr/^:([^!]+)!(\S+)@(\S+) PRIVMSG ([#&]\S+) :\s*(.+?)([.?!]*)?\s*$/;

	my $WHISPERED_TO	= qr/^:([^!]+)!(\S+)@(\S+) PRIVMSG [^#& ]+ :\s*[\-\+]?(.+?)\s*$/;
	my $SPOKEN_TO_1		= qr/^:([^!]+)!(\S+)@(\S+) PRIVMSG ([#&]\S+) :\s*[\-\+]?$my_nick(?:[,:]|\s+)\s*(.*?)\s*$/i;	# "$nick, hello" spoken directly to
	my $SPOKEN_TO_2		= qr/^:([^!]+)!(\S+)@(\S+) PRIVMSG ([#&]\S+) :\s*[\-\+]?(.+?)\s*,?\s*$my_nick\s*$/i;	# "hello $nick"  - indirect
	my $SPOKEN_TO_3		= qr/^:([^!]+)!(\S+)@(\S+) PRIVMSG ([#&]\S+) :\s*[\-\+]?$my_nick_nonum(?:[,:]|\s+)\s*(.*?)\s*$/i;	# "$nick, hello" spoken directly to
	my $SPOKEN_TO_4		= qr/^:([^!]+)!(\S+)@(\S+) PRIVMSG ([#&]\S+) :\s*[\-\+]?(.+?)\s*,?\s*$my_nick_nonum\s*$/i;	# "hello $nick"  - indirect
	my $NOT_SPOKEN_TO	= qr/^:([^!]+)!(\S+)@(\S+) PRIVMSG ([#&]\S+) :\s*(.+?)\s*$/;
	my $EVAL		= qr/^:([^!]+)!(\S+)@(\S+) PRIVMSG ([#&]\S+) :\s*(eval.+?)\s*$/;

	
	# was the bot spoken to in a private message (from user to bot PRIVMSG)?
#	          $self->act(SAY => $chan, $self->eval($1));

#	if (/$EVAL/)
#	{
#		$self->set(user_nick => $1, user_name => $2, user_mask => $3, chan => $4, query => $5, punctuation => ($6 || ""), whisper => 0);
#
 #               return if $self->ignore_user_check($1);
#                
#                # ignore whole channel?
#                return if $self->ignore_channel_check($4);
#                        
#                $self->spoken_to;
#	}
#	els
if ( /$WHISPERED_TO/ )
	{

		$self->set(user_nick => $1, user_name => $2, user_mask => $3, chan => $1, query => $4, punctuation => ($5 || ""), whisper => 1);
		
		# ignore user?
		return if $self->ignore_user_check($1);

		$self->spoken_to;
		
	}
	# the bot was spoken to while in a channel (i.e. <Chris62vw> Chrisbot: Hi!)
	elsif ( /$SPOKEN_TO_1/ || /$SPOKEN_TO_2/ )
	{
        
		$self->set(user_nick => $1, user_name => $2, user_mask => $3, chan => $4, query => $5, punctuation => ($6 || ""), whisper => 0);
		
		# ignore user?
		return if $self->ignore_user_check($1);

		# ignore whole channel?
		return if $self->ignore_channel_check($4);

		$self->spoken_to;
		
	}
	elsif ( /$SPOKEN_TO_3/ || /$SPOKEN_TO_4/ )
	{
        #need to set flag to not talk!
		$self->set(user_nick => $1, user_name => $2, user_mask => $3, chan => $4, query => $5, punctuation => ($6 || ""), whisper => 0, notalk=>1);
		
		# ignore user?
		return if $self->ignore_user_check($1);

		# ignore whole channel?
		return if $self->ignore_channel_check($4);

		$self->spoken_to;
		$self->set(notalk => 0);
		
	}
	# not spoken to	in a channel
	elsif ( /$NOT_SPOKEN_TO/ )
	{

		$self->set(user_nick => $1, user_name => $2, user_mask => $3, chan => $4, query => $5, punctuation => ($6 || ""), whisper => 0);

		# it's a query if we're on a LISTEN_ON channel
		if ($self->contains($4, [split /\s+/, $self->bot_cfg("LISTEN_ON")||""]))
		{

			# ignore user?
			return if $self->ignore_user_check($1);

			# do karma check
			$self->karma_check;

			# look for URIs to be saved
			$self->uri_in_msg_check($5, $4);

			$self->spoken_to;

		}
		# just chat otherwise (not being spoken to)
		else
		{

			# ignore user?
			return if $self->ignore_user_check($1);

			# do karma check
			$self->karma_check;

			# look for URIs to be saved
			$self->uri_in_msg_check($5, $4);

			$self->not_spoken_to;

		}
			
	}

}

1;
