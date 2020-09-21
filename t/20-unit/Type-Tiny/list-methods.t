=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Tiny's list processing methods.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Types::Standard -types;

is_deeply(
	[ Int->grep(qw/ yeah 1 1.5 hello world 2 /, [], qw/ 3 4 5 /, '' ) ],
	[ qw/ 1 2 3 4 5 / ],
	'Int->grep',
);

is(
	Int->first(qw/ yeah 1.5 hello world 2 /, [], qw/ 3 4 5 /, '' ),
	2,
	'Int->first',
);

my $e = exception { Int->map( qw/ yeah 1 1.5 hello world 2 /, [], qw/ 3 4 5 /, '' ) };
like( $e, qr/no coercion/i, 'map() requires a coercion' );

my $Rounded = Int->plus_coercions( Num, sub { int $_ } );

is_deeply(
	[ $Rounded->map( qw/ 1 2.1 3 4 5 / ) ],
	[ qw/ 1 2 3 4 5 / ],
	'$Rounded->map',
);

is_deeply(
	[ $Rounded->map( qw/ 1 2.1 foo 4 5 / ) ],
	[ qw/ 1 2 foo 4 5 / ],
	'$Rounded->map with uncoercible values',
);

is_deeply(
	[ Int->sort(qw/ 11 2 1 /) ],
	[ qw/ 1 2 11 / ],
	'Int->sort',
);

is_deeply(
	[ $Rounded->sort(qw/ 11 2 1 /) ],
	[ qw/ 1 2 11 / ],
	'$Rounded->sort',
);

is_deeply(
	[ Str->sort(qw/ 11 2 1 /) ],
	[ qw/ 1 11 2 / ],
	'Str->sort',
);

is_deeply(
	[ Int->rsort(qw/ 11 2 1 /) ],
	[ reverse qw/ 1 2 11 / ],
	'Int->rsort',
);

is_deeply(
	[ $Rounded->rsort(qw/ 11 2 1 /) ],
	[ reverse qw/ 1 2 11 / ],
	'$Rounded->rsort',
);

is_deeply(
	[ Str->rsort(qw/ 11 2 1 /) ],
	[ reverse qw/ 1 11 2 / ],
	'Str->rsort',
);

ok(
	! Int->any(qw//),
	'not Int->any(qw//)',
);

ok(
	Int->any(qw/ foo 1 bar /),
	'Int->any(qw/ foo 1 bar /)',
);

ok(
	! Int->any(qw/ foo bar /),
	'not Int->any(qw/ foo bar /)',
);

ok(
	Int->any(qw/ 1 2 3 /),
	'Int->any(qw/ 1 2 3 /)',
);

ok(
	Int->all(qw//),
	'Int->all(qw//)',
);

ok(
	! Int->all(qw/ foo 1 bar /),
	'not Int->all(qw/ foo 1 bar /)',
);

ok(
	! Int->all(qw/ foo bar /),
	'not Int->all(qw/ foo bar /)',
);

ok(
	Int->all(qw/ 1 2 3 /),
	'Int->all(qw/ 1 2 3 /)',
);

like(
	exception { Int->assert_any(qw//) },
	qr/Undef did not pass type constraint/,
	'Int->assert_any(qw//) --> exception',
);

is_deeply(
	[ Int->assert_any(qw/ foo 1 bar /) ],
	[ qw/ foo 1 bar / ],
	'Int->assert_any(qw/ foo 1 bar /)',
);

like(
	exception { Int->assert_any(qw/ foo bar /) },
	qr/Value "bar" did not pass type constraint/,
	'Int->assert_any(qw/ foo bar /) --> exception',
);

is_deeply(
	[ Int->assert_any(qw/ 1 2 3 /) ],
	[ qw/ 1 2 3 / ],
	'Int->assert_any(qw/ 1 2 3 /)',
);

is_deeply(
	[ Int->assert_all(qw//) ],
	[ ],
	'Int->assert_all(qw//)',
);

like(
	exception { Int->assert_all(qw/ foo 1 bar /) },
	qr/Value "foo" did not pass type constraint/,
	'Int->assert_all(qw/ foo 1 bar /) --> exception',
);

like(
	exception { Int->assert_all(qw/ foo bar /) },
	qr/Value "foo" did not pass type constraint/,
	'Int->assert_all(qw/ foo bar /) --> exception',
);

is_deeply(
	[ Int->assert_all(qw/ 1 2 3 /) ],
	[ qw/ 1 2 3 / ],
	'Int->assert_all(qw/ 1 2 3 /)',
);

done_testing;
