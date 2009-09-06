package Chrisbot;

# Copyright (c) 2002-2004 Chris Angell (chris@chrisangell.com). All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

# IRC Bot version 0.3

# core functions integral to basic functionality

use strict;
use warnings;

use lib "/home/simcop/perlbot/";

use Carp qw(carp cluck croak confess);
use IO::Socket;
use POSIX;
use Chrisbot::Parser;
use base qw(Chrisbot::Config Chrisbot::Actions Chrisbot::Common Chrisbot::Pipeline Chrisbot::Util::Facts Chrisbot::Util::Karma Chrisbot::Util::UserAccess Chrisbot::Util::Eval);


# socket connection to the irc network
my $SOCK;

# start message
my $START_MSG = "Chrisbot v.3 starting";

my $PARENT_PID = $$;


# public methods


sub new
{
	
	# initialize configuration ala config file and return an object instance
	
	my ($proto, $config_file) = @_;

	defined $config_file or die "usage: " . __PACKAGE__ . qq(->new("/path/to/config_file")\n);
	
	Chrisbot::Config->new_bot_cfg($config_file);
	
	return bless { }, ref($proto) || $proto;

}


sub init
{

	# connect to irc server

	my ($self) = @_;

	# set uid to desired user
	_change_uid($self);

	# now would be a safe time to print the start message
	$self->log_msg($START_MSG);
	
	# get settings from bot's config file
	my $nick	= $self->bot_cfg("NICK");
	my $user	= $self->bot_cfg("USER") || $self->bot_cfg("NICK");
	my $server	= $self->bot_cfg("SERVER_ADDRESS") . ':' . ( $self->bot_cfg("SERVER_PORT") || 6667 );

	# arguments to be passed to IO::Socket::INET->new
	my %INET_cfg = (PeerAddr => $server);
	
	# bind to a particular address locally?
	if (defined( my $bind_to_address = $self->bot_cfg("LOCAL_ADDRESS")))
	{

		$INET_cfg{LocalAddr} = $bind_to_address;

	}

	# bind to a particular port locally?  Useful if machine is firewalled
	if (defined( my $bind_to_port = $self->bot_cfg("LOCAL_PORT")))
	{

		$INET_cfg{LocalPort} = $bind_to_port;

	}

	# wait half a second - just in case the bot restarted and the irc network hasn't finished its housekeeping chores (removing user from channels, etc.)
	select("", "", "", 0.5);
	
	# connect to irc server	
 	$SOCK = IO::Socket::INET->new(%INET_cfg) or die "Fatal Error: Problem connecting to irc server $server: $@";

	# Give NICK and USER to irc server
	$self->act(SET_NICK => $nick);

	# identify to nickserv or relevant entity
	$self->act("IDENTIFY");
	
	# join channels
	if (defined (my $channels = $self->bot_cfg("CHANNELS")))
	{
	
		# some networks let you do JOIN #chan1,#chan2,#chan3,etc.
		# others make the user join one channel at a time
		# the config file allows for both methods
		# set JOIN_CHAN to #ch1,#ch2,#ch3, etc. to join all at once
		# or use $ch1 #ch2 #ch3 to join each channel one at a time
		
		$self->act(JOIN_CHAN =>  $_) for split /\s+/, $channels; 
	
	}
	else
	{

		# maybe someone might want a privmsg only bot
		$self->log_msg("Notice: Not joining any channels (no CHANNELS entry in config file)");

	}
		
}


sub daemonize
{

	# put the process in the background, detatch from terminal, etc.

	my ($self) = @_;

	# fork
	fork and exit;
	
	# detatch
	POSIX::setsid() or die "Can't start a new session: $!";

	if (defined( my $path = $self->bot_cfg("CHDIR_PATH") ))
	{

		$ENV{HOME} = $path;
		chdir;  # implicitly uses $ENV{HOME}

	}
	
	# catch SIGINT and SIGHUP - both will call restart_bot
	$SIG{INT} = $SIG{HUP} = sub { restart_bot($self, "Received a restart SIG") };
	
	# store new PID in relevant file
	_store_pid($self);
	
	# change mask
	umask 0022;

	# redirect STDIN, OUT, and ERR to either a logfile or to /dev/null
	my $botlog = $self->bot_cfg("LOGFILE") || "/dev/null";

	open STDIN,  "+>>$botlog" or die "Fatal Error: problem opening bot logfile $botlog: $! (bad LOGFILE entry in config file?)";
	open STDOUT, "+>&STDIN";
	open STDERR, "+>&STDIN";

	# change the "name" of the program
	# this doesn't work on all systems, and the exact effects of changing $0 vary from system to system
	if (defined (my $prog_name = $self->bot_cfg("PROGRAM_NAME")))
	{

		$0 = $prog_name;

	}

	# finally, log a basic start message
	$self->log_msg("$START_MSG (forked and daemonized from $PARENT_PID)");
	
}


sub start_session
{

	my ($self) = @_;
	
	my $raw_log_handle;

	# log raw data?
	if (defined( my $raw_log_file = $self->bot_cfg("RAW_LOG")))
	{

		open $raw_log_handle, ">>$raw_log_file" or die "Fatal Error: Problem opening raw log $raw_log_file: $! (bad RAW_LOG entry in config file?)";

		# turn off buffering
		select((select($raw_log_handle), $|=1)[0]);

	}

	while (defined ( my $line = <$SOCK> ) )
	{

		# print raw data to raw data log if applicable
		if (defined $raw_log_handle)
		{

			print $raw_log_handle scalar localtime() . " " . $line;

		}

		# send data to be parsed		
		Chrisbot::Parser::parse($self, $line);

	}

	close $raw_log_handle if defined $raw_log_handle;

}


sub _store_pid
{

	my ($self) = @_;

	# store PID away
	if (defined (my $pid = $self->bot_cfg("PIDFILE")))
	{
	
		open PID, ">$pid" or $self->log_msg("Warning: Couldn't open $pid to write pid: $! (bad PIDFILE entry in config file?)"), return;
		print PID $$;
		close PID;

	}

}


sub _change_uid
{

	# run as particular user
	
	my ($self) = @_;

	if (defined (my $runas_user = $self->bot_cfg("RUNAS_LOCAL_USER")))
	{

		# skip next part if RUNAS == current user
		unless (getpwuid($>) eq $runas_user)
		{
		
			# need to be root for these operations
			if ($> == 0)
			{
			
				# use defined, and not a simple truth check, so the bot may
				# be run as root.  Bad idea?  That is for the user to decide
				# maybe someone wants to run a bot as root so the bot can do
				# root-like things on the host machine
				defined ($> = $< = getpwnam($runas_user)) or $self->log_msg("Fatal Error: No such user: $runas_user (bad RUNAS_LOCAL_USER value in config file?)"), exit;
				
				# don't set group
				# defined ($) = getgrnam($runas_user)) or $self->log_msg("Fatal Error: No such group: $runas_user (bad RUNAS_LOCAL_USER value in config file?)";

				# but at least we can warn
				$> == 0 and warn "Warning: running this program as the superuser is not advised.  See the RUNAS_LOCAL_USER config value.";
				
			}
			else
			{

				$self->log_msg(sprintf "Fatal Error: Can't run as $runas_user: bot needs to be started by a superuser (root).  Current username is %s, UID is $>", getpwuid($>));
				exit;

			}

		}
			
	}

}


sub print_to_server
{

	# outputs to server

	my ($self, $line) = @_;

	# just in case
	chomp $line;

	# this should never ever happen, but just in case
	confess "\$line =~ /^\$/ matched" if $line =~ /^$/;

#	cluck "DYING?!? on ::: $line ::: $SOCK";


	print $SOCK $line . "\n";
}


sub log_msg
{

	# print to stderr
	# where the warning appears depends on how STDERR is being handled
	# STDERR may be directed to a logfile, to /dev/null, or to a terminal if the program is run in the foreground
	
	my ($self, $msg) = @_;

	defined $msg or croak "need message";

	my $warning = sprintf "%s  %s (%5.d): $msg\n",  scalar(localtime), $self->bot_cfg("PROGRAM_NAME") || $0, $$;

	warn $warning;

}


sub restart_bot
{

	# restart bot
	
	my ($self, $msg) = @_;
	
	if (defined( my $script = $self->bot_cfg("STARTUP_SCRIPT") ))
	{

		$self->log_msg("Restarting: $msg");

		exec $script or die "Problem restarting bot: can't exec $script: $!";
		
	}
	else
	{

		$self->log_msg("Warnings: START_SCRIPT is not defined in the bot config file.  Program is terminating...");
	}
	
	exit;

}


sub set
{

	# set class data
	
	my ($self) = shift;
	
	croak "need args" unless @_;
	
	# parameters come in key=val combinations, i.e. a hash assignment
	croak "uneven amount of key/val combinations passed" if @_ % 2;
	
	while (my ($key, $val) = splice @_, 0, 2)
	{

		# set	
		$self->{$key} = $val;

	}

}


sub get
{

	# get class data
	
	my ($self) = shift;

	# croak unless there is a value, or are values, to get
	croak "need key" unless 0 < @_;
	
	# hash slice. covers both scalar and list context
	return @{$self}{@_};

}


1;
