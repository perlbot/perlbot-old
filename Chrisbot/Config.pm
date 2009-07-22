package Chrisbot::Config;

use strict;
use warnings;
use Tie::File;

my %CONFIG;		# holds key/value config values

sub new_bot_cfg
{

	my ($self, $config_file) = @_; 

	defined $config_file or die "usage: \$obj->new_bot_cfg(\$config_filename)";
	
	open my $cfg_fh, $config_file or die "FATAL ERROR: Problem reading config file $config_file: $!\n";

	while (local $_ = <$cfg_fh>)
	{

		# allow both shell and C-style comments and skip blank lines
		# a comment has to be on its own line, seperate of actual key/value pairs
		next if /^\s*(?:#|\/\/|$)/;

		# ignore options with no values
		next if /^\s*[^=]+?\s*=\s*$/;
		
		# if __END__ is seen on a line by itself, the config file parsing stops
		last if /^\s*__END__\s*$/i;
	
		# everything else is either a key = value pair, or a syntax error	
		unless (/^\s*([^=]+?)\s*=\s*(.+?)\s*$/)
		{
		
			my $thirty_or_so = substr $_, 0, 30;
			die qq(syntax error in config file $config_file at line $. near "$thirty_or_so".\n);

		}
			
		$CONFIG{$1} = $2;

	}

	close $cfg_fh;

	# location of the config file
	$CONFIG{CONFIGFILE} = $config_file;
	
}


sub bot_cfg 
{

	my ($self, $key, $val) = @_;

	# is it a set?
	if (defined $val)
	{

		$val = uc $val;
		
		tie my @cfg_file, "Tie::File", $CONFIG{CONFIGFILE} or die "tie Tie::File($CONFIG{CONFIGFILE}): $!";

		# new config value?  append the new key and value to the file
		unless (defined $CONFIG{$val})
		{

			push @cfg_file, "$key\t= $val";

		}
		else
		{
		
			# otherwise, set existing line in file
			for (@cfg_file)
			{

				# last if the s/// is successful
				last if s/^(\s*$key\s*=\s*).+?(\s*)$/$1$val$2/;

			}

		}
			
		untie @cfg_file;
	
		# "reload" %CONFIG to reflect the new values in the config file
		_reload_cfg($self);
		
	}

	# return new value, or just return value if it was a get
	return $CONFIG{$key};

}


sub _reload_cfg
{

	my ($self) = @_;
	
	# reloads configuration
	new_bot_cfg($self, $CONFIG{CONFIGFILE});

}


1;
