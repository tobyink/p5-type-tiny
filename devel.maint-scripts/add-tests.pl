#!/usr/bin/perl

use strict;
use warnings;
use Path::Tiny qw( path );

#	bleh => 'regexp'                   => qr/./,
my $new = <<'NEW_LINES';
	fail => 'object booling to false'  => do { package Local::OL::BoolFalse; use overload q[bool] => sub { 0 }; bless [] },
	fail => 'object booling to true'   => do { package Local::OL::BoolTrue;  use overload q[bool] => sub { 1 }; bless [] },
NEW_LINES

my $dir = path('t/21-types/');
for my $file ($dir->children) {
	my @lines = map {
		$_ =~ /^#TESTS/ ? ($new, $_) : $_
	} $file->lines_utf8;
	$file->spew_utf8(@lines);
}
