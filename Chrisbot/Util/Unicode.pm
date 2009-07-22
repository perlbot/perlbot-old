package Chrisbot::Util::Unicode;

# Copyright (c) 2007 Jason Rhinelander (jagerman@jagerman.com). All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

# UTF-8/Unicode character information by Jason Rhinelander (jagerman)

use strict;
use warnings;

use Unicode::UCD qw/charinfo/;
use Encode qw/encode/;

my %special;
@special{0 .. 31, 127 .. 159} = qw{
	NUL SOH STX ETX EOT ENQ ACK BEL BS HT LF VT FF CR SO SI DLE DC1 DC2 DC3 DC4 NAK SYN ETB CAN EM SUB ESC FS GS RS US DEL
	PAD HOP BPH NBH IND NEL SSA ESA HTS HTJ VTS PLD PLU RI SS2 SS3 DCS PU1 PU2 STS CCH MW SPA EPA SOS SGCI SCI CSI ST OSC PM APC
};
my $regex = qr{
	(
		(?:0?x | [Uu]\+?)? [[:xdigit:]]+ (?:_[[:xdigit:]]+)*  # Hex, such as: 0x203d, x203d, 0x20_3d, etc.  single _'s allowed.  Also allows the U+0123 system.
	)
	|
	(
		0?b[01]+(?:_[01]+)*  # Binary, such as: 0b100000_00111101, b00100000_00111101, b10000000111101, etc. single _'s allowed.
	)
	|
	['"]?
	( # Bytes making up a utf8 character
		[\x00-\x7f] # 1 byte (0-7F)
		|
		[\xc2-\xdf][\x80-\xbf] # 2 bytes (80-7FF)
		|
		[\xe0-\xef][\x80-\xbf]{2} # 3 bytes (800-FFFF)
		|
		[\xf0-\xf3][\x80-\xbf]{3} # 4 bytes (10000-10FFFF)
	)
	['"]?
}ix;

sub info {
	my ($self, $unicode) = @_;

	$unicode =~ /^\s*$regex\s*$/ or return "That doesn't look like a valid UTF-8 character or unicode codepoint";

	my ($hex, $bin, $char) = ($1, $2, $3);
	my $cp;
	if (defined $hex) { $hex =~ s/^(?:U\+?|0?x)//i; $cp = hex $hex }
	elsif (defined $bin) { $cp = oct($bin) }
	else {
		# Manually get the codepoint from the encoded utf8 bytes.
		# This could be done with Encode::decode_utf8, but it doesn't guarantee that the result will be identical.
		my @char = split //, $char;
		if (@char == 1) {
			# 0b0xxxxxxx -- i.e. also an ASCII character
			$cp = ord($char);
		}
		else {
			# 0b110yyyyy_10zzzzzz -- 2 bytes for 8-11 bit codepoints (0byyyyyzzzzzz)
			# 0b1110xxxx_10yyyyyy_10zzzzzz -- 3 bytes for 12-16 bit codepoints (0bxxxxyyyyyyzzzzzz)
			# 0b11110www_10xxxxxx_10yyyyyy_10zzzzzz -- 4 bytes for 17-21 bit codepoints (0bwwwxxxxxxyyyyyyzzzzzz)
			#
			# The first byte has either 5 (2-byte sequence), 4 (3-byte) or 3 (4-byte) significant bits:
			$cp = ord(shift(@char) & (@char == 1 ? "\x1f" : @char == 2 ? "\xf" : "\x7"));
			# The remaining bytes all have 6 significant bits
			$cp = ($cp << 6) + ord(shift(@char) & "\x3f") while @char;
		}
	}

	my $uinfo = charinfo($cp) or return sprintf "\cBU+%04X\cB is not a valid unicode character.", $cp;

	my $utf8_char = encode("utf8", chr $cp);
	my $char_disp = $special{$cp} || $utf8_char;;
	my $ucode = sprintf "U+%04X", $cp;
	my $uname = $uinfo->{name} || '<unknown>';
	my $ublock = $uinfo->{block} || '<unknown>';
	my $utf8_encoding = join ' ', map sprintf('%02X', ord), split //, $utf8_char;

	my $case = $uinfo->{upper}
		? ", upper-case: U+$uinfo->{upper} (" . encode("utf8", chr hex $uinfo->{upper}) . ")"
		: $uinfo->{lower}
			? ", lower-case: U+$uinfo->{lower} (" . encode("utf8", chr hex $uinfo->{lower}) . ")"
			: '';
	return qq{\cB$char_disp $ucode "$uname"\cB, category: "$ublock", utf8 bytes: $utf8_encoding$case};
}

1;

# vim:noet:ts=4:sw=4
