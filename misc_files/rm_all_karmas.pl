#!/usr/bin/perl -w

use strict;
use DBI;

my $dbh = DBI->connect("dbi:SQLite(RaiseError=>1):/home/chrisangell/etc/chrisbot/v3/data/karma.db");

my $sth = $dbh->do("DELETE from karma");
