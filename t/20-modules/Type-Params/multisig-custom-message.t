=pod

=encoding utf-8

=head1 PURPOSE

Make sure that custom C<multisig()> messages work.

=head1 AUTHOR

Benct Philip Jonsson E<lt>bpjonsson@gmail.comE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018-2022 by Benct Philip Jonsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Type::Params qw( multisig );
use Types::Standard qw( Optional Str Int Bool Dict slurpy );


sub _maybe_slurpy {
	my @sig = @_;
	$sig[-1] = slurpy $sig[-1];
	return ( [@_], \@sig );
}

my $foo_args;
sub foo {
	$foo_args ||= multisig(
		{
			description => "parameter validation for foo()",
			message => 'USAGE: foo($string [, \%options|%options])',
		},
		_maybe_slurpy( Str, Dict[ bool => Optional[Bool], num => Optional[Int] ] ),
	);
	return $foo_args->(@_);
}

my $bar_args;
sub bar {
	$bar_args ||= multisig(
		{
			description => "parameter validation for bar()",
			message => 'USAGE: bar()',
		},
		[],
	);
	return $bar_args->(@_);
}

my @tests = (
	[ 'bar(1)' => sub { bar( 1 ) }, 'USAGE: bar()', undef ],
	[ 'bar()'  => sub { bar() },    "",             0 ],
	[
		'foo($string, num => "x")' => sub { foo( "baz", num => "x" ) },
		'USAGE: foo($string [, \\%options|%options])', undef,
	],
	[
		'foo([], num => 42)' => sub { foo( [], num => 42 ) },
		'USAGE: foo($string [, \\%options|%options])', undef,
	],
	[
		'foo($string, quux => 0)' => sub { foo( "baz", quux => 0 ) },
		'USAGE: foo($string [, \\%options|%options])', undef,
	],
	[
		'foo($string, [])' => sub { foo( "baz", [] ) },
		'USAGE: foo($string [, \\%options|%options])', undef,
	],
	[
		'foo($string, bool => 1)',
		sub {
			is_deeply
				[ foo( "baz", bool => 1 ) ],
				[ "baz", { bool => 1 } ],
				'slurpy options';
		},
		"",
		1,
	],
	[
		'foo($string, { bool => 1 })',
		sub {
			is_deeply
				[ foo( "baz", { bool => 1 } ) ],
				[ "baz", { bool => 1 } ],
				'hashref options';
		},
		"",
		0
	],
	[
	'foo($string)',
		sub {
			is_deeply
				[ foo( "baz" ) ],
				[ "baz", {} ],
				'no options';
		},
		"",
		1
	],
);

for my $test ( @tests ) {
	no warnings 'uninitialized';
	my($name, $code, $expected, $sig) = @$test;
	like( exception { $code->() } || '', qr/\A\Q$expected/, $name );
	is ${^TYPE_PARAMS_MULTISIG}, $sig, "$name \${^TYPE_PARAMS_MULTISIG}";
}

done_testing;
