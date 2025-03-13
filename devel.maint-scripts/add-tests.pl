#!/usr/bin/perl

use strict;
use warnings;
use Path::Tiny qw( path );

#	bleh => 'regexp'                   => qr/./,
my $new = <<'NEW_LINES';
	fail => 'boolean::false'           => boolean::false,
	fail => 'boolean::true'            => boolean::true,
	fail => 'builtin::false'           => do { builtin->can('false') ? builtin::false() : !!0 },
	fail => 'builtin::true'            => do { builtin->can('true') ? builtin::true() : !!1 },
NEW_LINES

my $dir = path('t/21-types/');
for my $file ($dir->children) {
	my @lines = map {
		$_ =~ /^#TESTS/ ? ($new, $_) : $_
	} $file->lines_utf8;
	$file->spew_utf8(@lines);
}
