#!/usr/bin/perl -w

use strict;
use DBI;

my $dbh = DBI->connect("dbi:SQLite(RaiseError=>1):/home/chrisangell/etc/chrisbot/v3/data/karma.db");

die "usage: $0 karma_item [karma_item_2, etc.]\n" unless @ARGV;

my $sth = $dbh->prepare("DELETE from karma WHERE lower(thing) = lower(?)");
$sth->execute($_) for @ARGV;
