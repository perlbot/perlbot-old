package Chrisbot::Util::Karma;

# Copyright (c) 2003-2004 Chris Angell (chris62vw@hotmail.com). All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

# IRC Bot version 0.3

# karms database module

use strict;
use warnings;
use Carp;
use DBI;

my $TABLE = "karma";
my $dbh;


sub karma
{

	my $self = shift;

	# connect to db if needed
	_connect_db($self) unless defined $dbh;
	
	my $action = lc shift;

	my $dispatch =
	{
		get			=> \&_get_karma,
		add			=> \&_add_karma,
		subtract	=> \&_subtract_karma,
		top_n		=> \&_top_n,
		bottom_n	=> \&_bottom_n,
	};

	if ( exists $dispatch->{$action} )
	{

		$dispatch->{$action}->(@_);

	}
	else
	{

		croak "there is no $action action";

	}	
	
}

sub _get_karma
{

	# return karma value for a thing
	my ($thing) = @_;

	# exception for user buu
	if (lc $thing eq "buu")
	{

		return (int (rand 1000) - 500);

	}
	
	my $query = "SELECT karma FROM $TABLE where lower(thing) = lower(?)";
	my $sth = $dbh->prepare($query);
	$sth->execute($thing);

	return $sth->fetchrow_array;

}

sub _add_karma
{

	# add to a thing's karma value
	my ($thing) = @_;

	# if thing doesn't have karma, initialize the thing
	_init_rec($thing) unless defined _get_karma($thing);

	# now add to karma
	my $query = "UPDATE $TABLE set karma = karma + 1 where lower(thing) = lower(?)";
	my $sth = $dbh->prepare($query);
	$sth->execute($thing);

}

sub _subtract_karma
{

	# subtract from a thing's karma value
	my ($thing) = @_;
	
	# if thing doesn't have karma, initialize the thing
	_init_rec($thing) unless defined _get_karma($thing);
	
	# now subtract from karma
	my $query = "UPDATE $TABLE set karma = karma - 1 where lower(thing) = lower(?)";
	my $sth = $dbh->prepare($query);
	$sth->execute($thing);

}

sub _top_n
{

	# return top n karma entries
	my ($n) = @_;

	my $query = "SELECT thing, karma FROM $TABLE ORDER BY karma DESC LIMIT $n";
	my $sth = $dbh->prepare($query);
	$sth->execute;

	return map { "$_->[0]: $_->[1]" } @{$sth->fetchall_arrayref};

}

sub _bottom_n
{

	# return bottom n karma entries
	my ($n) = @_;

	my $query = "SELECT thing, karma FROM $TABLE ORDER BY karma ASC LIMIT $n";
	my $sth = $dbh->prepare($query);
	$sth->execute;

	return map { "$_->[0]: $_->[1]" } @{$sth->fetchall_arrayref};

}

sub _init_rec
{

	# stick a 0 in a record so the "karma = karma +/- 1" will work
	
	my ($thing) = @_;
	
	my $query = "INSERT INTO $TABLE (thing, karma) VALUES (?, ?)";
	my $sth = $dbh->prepare($query);
	$sth->execute($thing, 0);


}

sub _connect_db
{

	my ($self) = @_;
	
	defined( my $db_file = $self->bot_cfg("KARMA_DB") ) or die
		sprintf "Fatal Error: KARMA_DB needs to be defined in %s\n", $self->bot_cfg("CONFIGFILE");

	$dbh = DBI->connect("dbi:SQLite(RaiseError=>1):$db_file");

}

1;
