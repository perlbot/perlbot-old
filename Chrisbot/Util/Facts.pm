package Chrisbot::Util::Facts;

# Copyright (c) 2003-2004 Chris Angell (chris62vw@hotmail.com). All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

# IRC Bot version 0.3

# factoid database module

use strict;
use warnings;
use Carp;
use DBI;
use LWP::Simple;
use XML::RSS::Parser;

my $TABLE = "facts";
my $dbh;

sub fact
{

	my ($self) = @_;

	# connect to db if needed
	_connect_db($self) unless defined $dbh;
	
	# splice the action parameter out of @_
	my $action = lc splice @_, 1, 1;

	my $dispatch =
	{
		get		=> \&_get_fact,
		add		=> \&_add_fact,
		remove	=> \&_remove_fact,
		search	=> \&_search_facts,
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


sub _get_fact
{

	my ($self, $keyword) = @_;

	my $query = "SELECT val FROM $TABLE where lower(key) = lower(?)";
	my $sth = $dbh->prepare($query);
	$sth->execute($keyword);

	my $fact = $sth->fetchrow_array;

        if ($fact && $fact =~ s/^rss:\s*//) {
          eval { $self->_get_rss($fact) }
        } else {
          $fact
        }
}

sub _get_rss
{
  my $self = shift;

  my $feed = XML::RSS::Parser->new->parse_string(
    get shift
  );

  ($feed->query('//item'))[0]->query('title')->text_content;
}

sub _add_fact
{

	my ($self, $keyword, $fact) = @_;

	# is there already an entry for a keyword in the fact database?	
	if (defined _get_fact($self, $keyword))
	{

		$self->set(FACT_MSG => "I already have an entry for $keyword");
		
		return;

	}

	my $query = "INSERT INTO $TABLE (key, val) VALUES (?, ?)";
	my $sth = $dbh->prepare($query);
	$sth->execute($keyword, $fact);
	
	$self->set(FACT_MSG => "added $keyword to the database");

	return 1;
	
}


sub _remove_fact
{

	my ($self, $keyword) = @_;

	# is the fact in the database?
	unless (defined _get_fact($self, $keyword))
	{

		$self->set(FACT_MSG => "I have no entry for $keyword");
		return;

	}

	my $query = "DELETE from $TABLE WHERE lower(key) = lower(?)";
	my $sth = $dbh->prepare($query);
	$sth->execute($keyword);
	
	$self->set(FACT_MSG => "removed $keyword from the database");

	return 1;
	
}


sub _search_facts
{

	my ($self, $search_str) = @_;

	# allowed input		SQL equivalent
	#
	# foo				%foo%
	# ^foo				foo%
	# foo$				%foo

	my ($first, $last);

	# check for anchor in front, strip if exists
	$first = $search_str =~ s/^\^// ? "" : "%";

	# same with anchor at end of string
	$last = $search_str =~ s/\$$// ? "" : "%";

	# quote...
	my $quoted_search_str = $dbh->quote($search_str);
	
	# but then take out the first and last '
	$quoted_search_str =~ s/'(.+)'/$1/;
	
	my $query = "SELECT key from $TABLE WHERE lower(val) like '$first$quoted_search_str$last'";
	my $sth = $dbh->prepare($query);
	$sth->execute();

	my $matches = $sth->fetchall_arrayref;

	return $matches;

}


sub _connect_db
{

	my ($self) = @_;
	
	defined( my $db_file = $self->bot_cfg("FACTS_DB") ) or die
		sprintf "Fatal Error: FACTS_DB needs to be defined in %s\n", $self->bot_cfg("CONFIGFILE");

	$dbh = DBI->connect("dbi:SQLite(RaiseError=>1):$db_file");

}


1;
