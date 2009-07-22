package Chrisbot::Util::Eval;

use strict;
use warnings;
no warnings qw/uninitialized numeric/;
use Data::Dumper;
use Symbol qw/delete_package/;
use BSD::Resource;

setrlimit(RLIMIT_CPU,-1,-1);

sub eval {
  my ($self, @args) = @_;
# fork
  my $pid = open my $eval, '-|';
  if (!$pid) {
    $self->_safe_execute(sub { $self->_eval(@args) });
    exit;
  }

  my $res;
  eval {
    local $SIG{ALRM} = sub { die "timeout\n" };
    alarm 3;
    $res = do { local $/; <$eval> };
    alarm 0;
  }; if ($@) {
    kill 15, $pid;
    select undef, undef, undef, 0.2;
    kill 9, $pid;
  }

  $res = "No output." unless defined $res;

  return substr($res, 0, 250);
}

# stolen from buubot2

sub _eval {
  my $self = shift;

  my $code = "no strict; no warnings; package main; ";
  $code .= "@_";

  my $roguevalue;
  my $printsub = \&CORE::print;
  local *CORE::GLOBAL::print = sub { $printsub->( @_ ); \$roguevalue };

  my $ret = eval $code;

  my $exception = $@;

  return if $ret == \$roguevalue;

  local $Data::Dumper::Terse = 1;
  local $Data::Dumper::Quotekeys = 0;
  local $Data::Dumper::Indent = 0;
  local $Data::Dumper::Useqq = 1;

  my $out = Dumper( $ret );

  if ( $exception ) {
    print "ERROR: $exception\n"
  } else {
    print "$out\n";
  }
}

sub _safe_execute
{
	my( $self, $code ) = @_;

	opendir my $dh, "/proc/self/fd" or die $!;
	while(my $fd = readdir($dh)) { next unless $fd > 2; POSIX::close($fd) }

	my $nobody_uid = getpwnam("nobody");
	die "Error, can't find a uid for 'nobody'. Replace with someone who exists" unless $nobody_uid;

        mkdir '/tmp/perlbot-jail';

	chdir("/tmp/perlbot-jail") or die $!;

	if( $< == 0 )
	{
		chroot(".") or die $!;
	}
	else
	{
		die "Must be root\n";
#    warn "Not root, won't try to chroot";
	}
	$<=$>=$nobody_uid;
	$(=$)=$nobody_uid;
	POSIX::setgid($nobody_uid); #We just assume the uid is the same as the gid. Hot.

	die "Error, failed to drop user" if $> < 65000;
	
	my $kilo = 1024;
	my $meg = $kilo * $kilo;
	my $limit = 50 * $meg;

	setrlimit(RLIMIT_CPU, 10,10);
	setrlimit(RLIMIT_DATA, $limit, $limit );
	setrlimit(RLIMIT_STACK, $limit, $limit );
	setrlimit(RLIMIT_NPROC, 1,1);
	setrlimit(RLIMIT_NOFILE, 0,0);
	setrlimit(RLIMIT_OFILE, 0,0);
	setrlimit(RLIMIT_OPEN_MAX,0,0);
	setrlimit(RLIMIT_LOCKS, 0,0);
	setrlimit(RLIMIT_AS,$limit,$limit);
	setrlimit(RLIMIT_VMEM,$limit, $limit);
	setrlimit(RLIMIT_MEMLOCK,100,100);
	#setrlimit(RLIMIT_MSGQUEUE,100,100);

	die "Failed to drop root: $<" if $< == 0;
	close STDIN;

	local $@;

	for( qw/IO::Socket::INET/ )
	{
		delete_package( $_ );
	}

	local @INC;
#  delete $self->{ irc }->{ $_ } #This is bad!
#    for qw/socket dcc wheelmap localaddr/;

	{
		#no ops qw(:base_thread :sys_db :subprocess :others);
		$code->();
	}
}

1;
