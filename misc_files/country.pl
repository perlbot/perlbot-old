#!/usr/bin/perl -w

use strict;
use DBI;

my $dbh = DBI->connect("dbi:SQLite(RaiseError=>1):/etc/chrisbot/v3/data/facts.db");

my $sth = $dbh->prepare("select * from facts where length(key) = 3"); 
$sth->execute;

my $i;
my @fix;

my @recs = grep { $_->[0] =~ /^\./ } @{ $sth->fetchall_arrayref };

rm("$_->[0]") and add($_->[0], $_->[0] . " is " . $_->[1]) for @recs;

print $_->[0] . " is " . $_->[1] . $/ for  @recs;

sub rm
{
	
	my $sth = $dbh->prepare("DELETE from facts WHERE lower(key) = lower(?)");

	 $sth->execute(pop);

}

sub add
{

	my $query = "INSERT INTO facts (key, val) VALUES (?, ?)";
	my $sth = $dbh->prepare($query);
	$sth->execute(@_);

}
