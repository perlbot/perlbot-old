#!/usr/bin/perl -w

use strict;
use DBI;

my $dbh = DBI->connect("dbi:SQLite(RaiseError=>1):/etc/chrisbot/v3/data/facts.db");

my $sth = $dbh->prepare("select * from facts"); 
$sth->execute;

my $i;
my @fix;

for (map @$_, @{ $sth->fetchall_arrayref })
{
   
	push @fix, $_ unless $i++ % 2

}

rm($ARGV[0]) if $ARGV[0];

print for grep /[A-Z]/, @fix;

sub rm
{
	
	my $sth = $dbh->prepare("DELETE from facts WHERE key = ?");

	 $sth->execute(pop);
	 
	 
	 
		
}
