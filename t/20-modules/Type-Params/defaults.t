=pod

=encoding utf-8

=head1 PURPOSE

Test C<compile> and C<compile_named> support defaults for parameters.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

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

@rv = ();
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

@rv = ();
is(
	exception { @rv = compile(Int, { default => \'(40+2)' })->() },
	undef,
	'compile: no exception thrown because of defaulted argument via Perl source code'
);

is_deeply(
	\@rv,
	[42],
	'compile: default applied correctly via Perl source code'
);

@rv = ();
is(
	exception { @rv = compile(ArrayRef, { default => [] } )->() },
	undef,
	'compile: no exception thrown because of defaulted argument via arrayref'
);

is_deeply(
	\@rv,
	[[]],
	'compile: default applied correctly via arrayref'
);

@rv = ();
is(
	exception { @rv = compile(HashRef, { default => {} } )->() },
	undef,
	'compile: no exception thrown because of defaulted argument via hashref'
);

is_deeply(
	\@rv,
	[{}],
	'compile: default applied correctly via hashref'
);

@rv = ();
is(
	exception { @rv = compile(Any, { default => undef } )->() },
	undef,
	'compile: no exception thrown because of defaulted argument via undef'
);

is_deeply(
	\@rv,
	[undef],
	'compile: default applied correctly via undef'
);

@rv = ();
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

@rv = ();
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

@rv = ();
is(
	exception { @rv = compile_named(thing => ArrayRef, { default => [] } )->() },
	undef,
	'compile_named: no exception thrown because of defaulted argument via arrayref'
);

is_deeply(
	\@rv,
	[{ thing => [] }],
	'compile_named: default applied correctly via arrayref'
);

@rv = ();
is(
	exception { @rv = compile_named(thing => HashRef, { default => {} } )->() },
	undef,
	'compile_named: no exception thrown because of defaulted argument via hashref'
);

is_deeply(
	\@rv,
	[{ thing => {} }],
	'compile_named: default applied correctly via hashref'
);

@rv = ();
is(
	exception { @rv = compile_named(thing => Any, { default => undef } )->() },
	undef,
	'compile_named: no exception thrown because of defaulted argument via undef'
);

is_deeply(
	\@rv,
	[{ thing => undef }],
	'compile_named: default applied correctly via undef'
);

like(
	exception { compile(HashRef, { default => \*STDOUT } ) },
	qr/Default expected to be/,
	'compile: exception because bad default'
);

done_testing;
