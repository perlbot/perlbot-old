package Chrisbot::Util::Host;

# Copyright (c) 2003 Chris Angell (chris62vw@hotmail.com). All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

# IRC Bot version 0.3

# access to host(1) - very quick dns resolution

use strict;
use warnings;

# make sure "any" and "soa" dont get in

my $HOSTUTIL = "/usr/bin/host";
my $HOSTCMD = $HOSTUTIL . " -t";
my $IPV6CALC = "/usr/local/bin/ipv6calc";

my @ALLOWED_TYPES = qw/a aaaa ptr mx ns cname/; 

sub new
{

	my ($class, $type, $host, $server) = @_;

	$type = lc $type;

	
	# only allow certain queries, and for obvious reasons	
	return "Sorry, type $type isn't allowed.  It might take up too much space here, or may be unsupported.  Allowed types are: @ALLOWED_TYPES"
		unless grep { $_ eq $type } @ALLOWED_TYPES;
	
	return "Bad input - whole string must not match [^\\w.-:]" if _tainted($host);

	return _resolve($type, $host, $server);

}

sub _resolve
{

	my ($type, $host, $server) = @_;

	# ipv6 PTR lookups are special. there are two ways to do the lookup
	# make arpa the default
	if ($type eq "ptr" and $host =~ /:/) {

		return _lookup(_ipv6_ptr_arpa_lookup($host, $server));

	} elsif ($type eq "ptrint") {

		return _lookup(_ipv6_ptr_int_lookup($host, $server));

	} elsif ($type eq "ptrarpa") {

		return _lookup(_ipv6_ptr_arpa_lookup($host, $server));
		
	} else {

		# nothing special
		return _lookup($type, $host, "127.0.0.1");

	}
	
}

sub _ipv6_ptr_int_lookup
{

	my ($host, $server) = @_;
	return ("ptr -n", $host, $server);

}

sub _ipv6_ptr_arpa_lookup
{

	my ($host, $server) = @_;
	# change IP to an easy to work with format that host(1) likes
 	my $calc_out = qx($IPV6CALC -q --out revnibbles.arpa $host); 

	return ("ptr", $calc_out, $server);

}

sub _tainted {

	# we want to disallow special characters like ` and ;
	# otherwise someone could do a "host `killall perl`" or similar
	# only let through characters that would be in a domain name or ipv4/ipv6 address

	return ( $_[0] =~ /[^\w.\: -]/ );

}

sub _lookup
{

	my ($type, $host, $server) = @_;

	my $host_output = qx($HOSTCMD $type $host $server);
	my @host_output = split /\n/, $host_output;

	# get rid of first five lines
	shift @host_output for 0..4;
		
	return "Record not found." unless @host_output;

	return join " :: ", @host_output;

}

1;
