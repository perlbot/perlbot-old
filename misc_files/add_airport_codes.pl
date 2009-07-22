#!/usr/bin/perl -w

use strict;
use DBI;

my $dbh = DBI->connect("dbi:SQLite(RaiseError=>1):/home/chrisangell/etc/chrisbot/v3/data/facts.db");

open my $fh, pop or die "can't open file: $!";

while (<$fh>)
{

	my ($key, $val) = /^(.+?): (.+)$/;

	die "key is $key and val is $val and one of them are false" unless $key && $val;

	my $sth = $dbh->prepare("insert into facts (key, val) values (?,?)"); 
	$sth->execute($key, $val);

}
