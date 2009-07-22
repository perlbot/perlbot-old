package Chrisbot::Actions;

# Copyright (c) 2003 Chris Angell (chris62vw@hotmail.com). All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

# IRC Bot version 0.3

use strict;
use warnings;
use Carp;


my $DISPATCH =
{

	RAW				=>	\&_raw,
	SAY				=>	\&_priv_msg,
	TALK			=>	\&_priv_msg,
	JOIN_CHAN		=>	\&_join_chan,
	PART_CHAN		=>	\&_part_chan,
	SET_NICK		=>	\&_set_nick,
	SET_TOPIC		=>	\&_set_topic,
	SET_MODE		=>	\&_set_mode,
	KICK			=>	\&_kick,
	BAN				=>	\&_ban,
	UNBAN			=>	\&_unban,
	INVISIBLE		=>	\&_invisible,
	WALLOPS			=>	\&_wallops,
	ACTION			=>	\&_action,
	PONG			=> 	\&_pong,
	CTCP_PING		=>	\&_ctcp_ping,
	CTCP_VERSION    =>  \&_ctcp_version,
	CTCP_TIME       =>  \&_ctcp_time,
	IDENTIFY		=>	\&_identify,
};


sub act {

	# prints various messages to the irc server
	
	my $self = shift;
	
	# keys can be any case
	my $action = uc shift;

	confess "there is no $action action" unless exists $DISPATCH->{$action};

	# might return nothing. only print if needed
	my $to_print = $DISPATCH->{$action}->($self, @_);
	
	print "TOSEND: $to_print\n";

	$self->print_to_server( $to_print ) if defined $to_print;

}

sub _raw
{

	shift if ref $_[0]; # get rid of object
	return @_;

}


sub _priv_msg
{

	my ($self, $chan, $output) = @_;

#	if (!$self->get("notalk"))
	{
		return "PRIVMSG $chan :$output";
	}
#	else
	{
		return undef;
	}

}


sub _join_chan
{

	my ($self, $chan) = @_;
	return "JOIN $chan";

}


sub _part_chan
{

	my ($self, $chan) = @_;
	return "PART $chan";

}


sub _set_nick
{

	my ($self, $nick) = @_;

	# set nickname via bot_cfg if the nick differs from the setting in the config file
	if ($nick ne $self->bot_cfg("NICK"))
	{
	
		$self->bot_cfg(NICK => $nick);
	
	}
		
	my $user = $self->bot_cfg("USER") || $nick;	
	
	# tell server our new name
	return "NICK $nick\nUSER $nick amd localhost :$nick\nPASS perlbot:falafel\n"

}


sub _set_topic
{

	my ($self, $chan, $topic) = @_;
	return "TOPIC $chan :$topic";

}


sub _set_mode
{

	my ($self, $mode) = @_;
	return "MODE $mode";

}


sub _kick
{

	my ($self, $chan, $who, $reason) = @_;
	$reason ||= "bye bye!";

	return "KICK $chan $who :$reason";

}


sub _ban
{

	my ($self, $chan, @who) = @_;
	my $bs = ("b") x @who;
	return "MODE $chan +$bs @who";

}


sub _unban
{   

	my ($self, $chan, @who) = @_;
	my $bs = ("b") x @who;
	return "MODE $chan -$bs @who";

}


sub _invisible
{

	my $self = shift;
	__set_mode("i", $_[0]);
	
}


sub _wallops
{

	my $self = shift;
	__set_mode("w", $_[0]); 

}


sub _action
{

	my ($self, $chan, $output) = @_;

#	if (!$self->get("notalk"))
	{
		return "PRIVMSG $chan :\x01ACTION $output\x01";
	}
#	else
	{
		return undef;
	}

}


sub _pong
{

	my ($self, $who) = @_;
	return "PONG $who";

}


sub _ctcp_ping
{

	my ($self, $who, $ping_time) = @_;
    $ping_time ||= time;
	return "NOTICE $who :\x01PING $ping_time\x01";

}


sub _ctcp_version
{

	my ($self, $who) = @_;
	my $version = $self->bot_cfg("VERSION") || 'Chrisbot v.3 by Chris Angell (chris@chrisangell.com)';
	return "NOTICE $who :\x01VERSION $version\x01";

}


sub _ctcp_time
{

	my ($self, $who) = @_;
	return "NOTICE $who :\x01TIME @{[ scalar localtime ]} PST\x01\n";

}


sub _identify
{
	
	# identify to server

	my ($self) = @_;

	if (defined( my $ident_pass = $self->bot_cfg("IDENTIFY_PASS")))
	{

		# who should we identify to?
		my $tell_who = $self->bot_cfg("IDENTIFY_TO_WHO") || "nickserv";
		
		# though I have never seen another command besides "identify", hey, who knows
		# maybe it's "register" or "login" on some networks
		my $ident_string = $self->bot_cfg("IDENTIFY_COMMAND_WORD") || "identify";

		# some irc networks allow users to identify as other users
		if (my $as_who = $self->bot_cfg("IDENTIFY_AS_WHO"))
		{

			$ident_string .= " " . $as_who;

		}
		
		# add the password	
		$ident_string .= " " . $ident_pass;

		# and send as privmsg
		act($self, SAY => $tell_who, $ident_string);

	}
	
}


##############################################
# functions that are internal to this module #
##############################################


sub __set_mode {

	# set modes like i, w, etc.

	# $_[0] can either be "on" or "off", case insensitive
	my ($mode_letter, $on_or_off) = @_;

	$on_or_off = /^(?:on|off)$/i or carp "bad argument";
	
	my $mode = ( $on_or_off =~ /^ON$/i ? "+$mode_letter" : "-$mode_letter" );

	return "MODE $mode";

}


1;
