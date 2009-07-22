package Chrisbot::Util::UserAccess;

# Copyright (c) 2004 Chris Angell (chris62vw@hotmail.com). All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

# IRC Bot version 0.3

# control who has access to the bot

# Levels
# 0 - denied access
# 1 - regular user
# 2 - admin
# 3 - operator
# 4 - owner

# The levels are used throught other parts of the program.  They are used to allow
# or deny access to any part of the software by simply checking the user that is
# accessing the bot to see what level he possesses by comparing the hostmask to a database
# full of usernames and hostmasks.


use strict;
use warnings;
use Carp;
use DBI;

my $TABLE = "users";
my $dbh;


sub user_access
{

	my $self = $_[0];

	# connect to db if needed
	_connect_db($self) unless defined $dbh;
	
	# splice the action parameter out of @_
	my $action = lc splice @_, 1, 1;

	my $dispatch =
	{
		validate		=> \&_validate_user,
		add_user		=> \&_add_user,
		delete_user		=> \&_delete_user,
		get_user_data	=> \&_get_user_data,
		check_mask		=> \&_check_mask,
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

sub _validate_user
{
	
	my ($self, $user, $need_level) = @_;

	# first, check hostmask to make sure user is even in the system
	return unless _check_mask($self, $user);

	# then get the user's access level number
	my $has_level = _get_level($self, $user);

	# now compare levels - return true if has level is
	# greater than or equal to the level needed
	return $has_level >= $need_level;
			
}

sub _get_level
{

	my ($self, $user) = @_;

	my %user_data = _get_user_data($self, $user);
	
	return $user_data{level};

}

sub _check_mask
{
	
	my ($self, $user) = @_;

	my $user_mask = $self->get("user_mask");

	my %user_data = _get_user_data($self, $user);

	return unless $user_data{hostmask};
	
	my $stored_mask = qr/$user_data{hostmask}/;

	return $user_mask =~ /$stored_mask/i;

}

sub _get_user_data
{
	
	# username, level,hostmask, password, email
	
	my ($self, $user, @wanted) = @_;

	my $query = "SELECT username, level,hostmask, password, email FROM $TABLE where lower(username) = lower(?)";
	my $sth = $dbh->prepare($query);
	$sth->execute($user);

	my %data;

	@data{qw/username level hostmask password email/} = $sth->fetchrow_array;
	
	return unless $data{username};
	
	if (@wanted)
	{

		return @wanted > 1 ? map { $data{$_} } @wanted : $data{$wanted[0]};

	}
	else
	{
	
		return %data;
	
	}
		
}

sub _user_exists
{

	return defined ${{_get_user_data(@_)}}{username};

}

sub _add_user
{

	# my ($self, $user, $level, $mask, $pw, $email) = @_;
	my $self = shift;
	
	my $user = $_[0];
	
	return "$user is already in the system" if _user_exists($self, $user);

	my $query = "INSERT INTO $TABLE (username, level, hostmask, password, email) VALUES (?, ?, ?, ?, ?)";
	my $sth = $dbh->prepare($query);
	$sth->execute(@_);
	
	return "added $user to the database";

}

sub _remove_user
{

	my ($self, $user) = @_;
	
	return "$user is not in the system" unless _user_exists($self, $user);

	my $query = "DELETE from $TABLE WHERE lower(username) = lower(?)";
	my $sth = $dbh->prepare($query);
	$sth->execute($user);
	
	return "removed $user from the database";

}

sub _connect_db
{

	my ($self) = @_;
	
	defined( my $db_file = $self->bot_cfg("USER_ACCESS_DB") ) or die
		sprintf "Fatal Error: USER_ACCESS_DB needs to be defined in %s\n", $self->bot_cfg("CONFIGFILE");
 
	$dbh = DBI->connect("dbi:SQLite(RaiseError=>1):$db_file");

}

1;
