#!/usr/bin/perl -w

# perlbot's startup file

use strict;
use lib "/home/chrisangell/etc/chrisbot/v3";
use Chrisbot;

my $bot = Chrisbot->new("/home/chrisangell/etc/chrisbot/v3/startup_and_cfg/home-perlbot.cfg");

$bot->init;
# $bot->daemonize;
$bot->start_session;
