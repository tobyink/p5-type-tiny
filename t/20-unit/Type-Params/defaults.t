use Test::More;
use Test::Fatal;
use Types::Standard -types;
use Type::Params qw( compile compile_named );

my @rv;
is(
	exception { @rv = compile(Int, { default => 42 } )->() },
	undef,
	'compile: no exception thrown because of defaulted argument'
);

is_deeply(
	\@rv,
	[42],
	'compile: default applied correctly'
);

is(
	exception { @rv = compile(Int, { default => sub { 42 } } )->() },
	undef,
	'compile: no exception thrown because of defaulted argument via coderef'
);

is_deeply(
	\@rv,
	[42],
	'compile: default applied correctly via coderef'
);

my @rv;
is(
	exception { @rv = compile_named(thing => Int, { default => 42 } )->() },
	undef,
	'compile_named: no exception thrown because of defaulted argument'
);

is_deeply(
	\@rv,
	[{ thing => 42 }],
	'compile_named: default applied correctly'
);

is(
	exception { @rv = compile_named(thing => Int, { default => sub { 42 } } )->() },
	undef,
	'compile_named: no exception thrown because of defaulted argument via coderef'
);

is_deeply(
	\@rv,
	[{ thing => 42 }],
	'compile_named: default applied correctly via coderef'
);

done_testing;
