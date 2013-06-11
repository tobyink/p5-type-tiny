=pod

=encoding utf-8

=head1 PURPOSE

Test L<Type::Utils> C<match_on_type> and C<compile_match_on_type> functions.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

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
	=> sub { die "$_ is not acceptable json type" },
);

is(
	to_json({foo => 1, bar => 2, baz => [3 .. 5], quux => undef}),
	'{ "bar" : 2, "baz" : [ 3, 4, 5 ], "foo" : 1, "quux" : null }',
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
		=> sub { die "$_ is not acceptable json type" },
	);
}

is(
	to_json_2({foo => 1, bar => 2, baz => [3 .. 5], quux => undef}),
	'{ "bar" : 2, "baz" : [ 3, 4, 5 ], "foo" : 1, "quux" : null }',
	'to_json_2 using match_on_type works',
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

done_testing;
