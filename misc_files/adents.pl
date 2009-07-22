#!/usr/bin/perl -w

use strict;
use DBI;

my $dbh = DBI->connect("dbi:SQLite(RaiseError=>1):/etc/chrisbot/v3/data/facts.db");

while (local $_ = <STDIN>)
{

	# skip blanks and comments
	next if /^#/ || /^\s+$/;

	my ($key, $val) = /^\s*(.+?)\s+is\s+(.+?)\s*$/;

	die "key is $key and val is $val and one of them are false" unless $key && $val;

	my $sth = $dbh->prepare("insert into facts (key, val) values (?,?)"); 
	$sth->execute($key, $val);

}
