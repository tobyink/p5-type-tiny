#!/usr/bin/env perl

use v5.014;
use Path::Tiny;
use Path::Iterator::Rule;

use constant LIB_DIR  => path(path(__FILE__)->absolute->dirname)->parent->child('lib');
use constant TEST_DIR => path(path(__FILE__)->absolute->dirname)->parent->child('t/20-modules');

my $rule = Path::Iterator::Rule->new->file->perl_module;
my $iter = $rule->iter( LIB_DIR );

while (my $file = $iter->())
{
	my $module = path($file)->relative(LIB_DIR);
	$module =~ s{.pm$}{};
	$module =~ s{/}{::}g;

	TEST_DIR->child($module =~ s/::/-/gr)->exists
		or ($module =~ /^Types::Standard::/)   # helper module
		or say $module;
}
