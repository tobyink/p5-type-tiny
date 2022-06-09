=pod

=encoding utf-8

=head1 PURPOSE

Test L<Type::Utils> C<match_on_type> and C<compile_match_on_type> functions.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Type::Utils qw( match_on_type compile_match_on_type );
use Types::Standard -types;

sub to_json;

*to_json = compile_match_on_type(
	HashRef() => sub {
		my $hash = shift;
		'{ '
			. (
			join ", " =>
			map { '"' . $_ . '" : ' . to_json( $hash->{$_} ) }
			sort keys %$hash
		) . ' }';
	},
	ArrayRef() => sub {
		my $array = shift;
		'[ ' . ( join ", " => map { to_json($_) } @$array ) . ' ]';
	},
	Num()   => q {$_},
	Str()   => q { '"' . $_ . '"' },
	Undef() => q {'null'},
	ScalarRef() &+ sub { Bool->check($$_) } => q { $$_ ? 'true' : 'false' },
	=> sub { die "$_ is not acceptable json type" },
);

is(
	to_json({foo => 1, bar => 2, baz => [3 .. 5], quux => undef, xyzzy => \1 }),
	'{ "bar" : 2, "baz" : [ 3, 4, 5 ], "foo" : 1, "quux" : null, "xyzzy" : true }',
	'to_json using compile_match_on_type works',
);

sub to_json_2
{
	return match_on_type $_[0] => (
		HashRef() => sub {
			my $hash = shift;
			'{ '
				. (
				join ", " =>
				map { '"' . $_ . '" : ' . to_json_2( $hash->{$_} ) }
				sort keys %$hash
			) . ' }';
		},
		ArrayRef() => sub {
			my $array = shift;
			'[ ' . ( join ", " => map { to_json_2($_) } @$array ) . ' ]';
		},
		Num()   => q {$_},
		Str()   => q { '"' . $_ . '"' },
		Undef() => q {'null'},
		ScalarRef() &+ sub { Bool->check($$_) } => q { $$_ ? 'true' : 'false' },
		=> sub { die "$_ is not acceptable json type" },
	);
}

is(
	to_json_2({foo => 1, bar => 2, baz => [3 .. 5], quux => undef, xyzzy => \1 }),
	'{ "bar" : 2, "baz" : [ 3, 4, 5 ], "foo" : 1, "quux" : null, "xyzzy" : true }',
	'to_json_2 using match_on_type works',
);

like(
	exception { to_json(do { my $x = "hello"; \$x }) },
	qr{\ASCALAR\(\w+\) is not acceptable json type},
	"fallthrough works for compile_match_on_type",
);

like(
	exception { to_json_2(do { my $x = "hello"; \$x }) },
	qr{\ASCALAR\(\w+\) is not acceptable json type},
	"fallthrough works for match_on_type",
);

my $compiled1 = compile_match_on_type(
	HashRef()  => sub { 'HASH' },
	ArrayRef() => sub { 'ARRAY' },
);

is(ref($compiled1), 'CODE', 'compile_match_on_type returns a coderef');
is($compiled1->({}), 'HASH', '... correct result');
is($compiled1->([]), 'ARRAY', '... correct result');
like(
	exception { $compiled1->(42) },
	qr/^No cases matched for Value "?42"?/,
	'... correct exception',
);

if ($ENV{EXTENDED_TESTING})
{
	require Benchmark;
	my $iters = 5_000;
	
	my $standard = Benchmark::timethis(
		$iters,
		'::to_json_2({foo => 1, bar => 2, baz => [3 .. 5], quux => undef})',
		'standard',
		'none',
	);
	diag "match_on_type: " . Benchmark::timestr($standard);
	
	my $compiled = Benchmark::timethis(
		$iters,
		'::to_json({foo => 1, bar => 2, baz => [3 .. 5], quux => undef})',
		'compiled',
		'none',
	);
	diag "compile_match_on_type: " . Benchmark::timestr($compiled);
}

like(
	exception {
		match_on_type([], Int, sub { 44 });
	},
	qr/^No cases matched/,
	'match_on_type with no match',
);

like(
	exception {
		compile_match_on_type(Int, sub { 44 })->([]);
	},
	qr/^No cases matched/,
	'coderef compiled by compile_match_on_type with no match',
);

our $context;
MATCH_VOID: {
	match_on_type([], ArrayRef, sub { $context = wantarray });
	ok(!defined($context), 'match_on_type void context');
};
MATCH_SCALAR: {
	my $x = match_on_type([], ArrayRef, sub { $context = wantarray });
	ok(defined($context) && !$context, 'match_on_type scalar context');
};
MATCH_LIST: {
	my @x = match_on_type([], ArrayRef, sub { $context = wantarray });
	ok(defined($context) && $context, 'match_on_type list context');
};
MATCH_VOID_STRINGOFCODE: {
	match_on_type([], ArrayRef, q{ $::context = wantarray });
	ok(!defined($context), 'match_on_type void context (string of code)');
};
MATCH_SCALAR_STRINGOFCODE: {
	my $x = match_on_type([], ArrayRef, q{ $::context = wantarray });
	ok(defined($context) && !$context, 'match_on_type scalar context (string of code)');
};
MATCH_LIST_STRINGOFCODE: {
	my @x = match_on_type([], ArrayRef, q{ $::context = wantarray });
	ok(defined($context) && $context, 'match_on_type list context (string of code)');
};
my $compiled = compile_match_on_type(ArrayRef, sub { $context = wantarray });
COMPILE_VOID: {
	$compiled->([]);
	ok(!defined($context), 'compile_match_on_type void context');
};
COMPILE_SCALAR: {
	my $x = $compiled->([]);
	ok(defined($context) && !$context, 'compile_match_on_type scalar context');
};
COMPILE_LIST: {
	my @x = $compiled->([]);
	ok(defined($context) && $context, 'compile_match_on_type list context');
};

done_testing;
