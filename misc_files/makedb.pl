#!/usr/bin/perl
use DBI;
use strict;
my $db = DBI->connect_cached('dbi:SQLite(RaiseError=>1):/home/chrisangell/etc/chrisbot/v3/data/users.db');

$db->do(q{
		create table users
		(
			username varchar(512) not null,
			level varchar(512) not null,
			hostmask varchar(512) not null,
			password varchar(512) not null,
			email varchar(512) not null
		)
	});
