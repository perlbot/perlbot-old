#!/usr/bin/perl -w

# perlbot's startup file

use strict;
use lib "/home/ryan/perlbot/chrisbot/v3";
#use lib "/home/ryan/perlbot/chrisbot/v3/lib/perl/5.10.0";
use Chrisbot;

my $bot = Chrisbot->new("freenode-perlbot.cfg");

$bot->init;
#$bot->daemonize;
$bot->start_session;
