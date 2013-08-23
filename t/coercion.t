=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Coercion works.

=head1 DEPENDENCIES

Uses the bundled BiggerLib.pm type library.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::Fatal;

use BiggerLib -types, -coercions;

is(
	BigInteger->coercion->coerce(2),
	12,
	'coercion works',
);

is(
	BigInteger->coercion->(2),
	12,
	'coercion overloads &{}',
);

ok(
	BigInteger->coercion->has_coercion_for_type(ArrayRef),
	'BigInteger has_coercion_for_type ArrayRef',
);

ok(
	BigInteger->coercion->has_coercion_for_type(SmallInteger),
	'BigInteger has_coercion_for_type SmallInteger',
);

ok(
	!BigInteger->coercion->has_coercion_for_type(HashRef),
	'not BigInteger has_coercion_for_type SmallInteger',
);

cmp_ok(
	BigInteger->coercion->has_coercion_for_type(BigInteger),
	eq => '0 but true',
	'BigInteger has_coercion_for_type BigInteger eq "0 but true"'
);

my $BiggerInteger = BigInteger->create_child_type(
	constraint => sub { $_ > 1_000_000 },
);

cmp_ok(
	BigInteger->coercion->has_coercion_for_type($BiggerInteger),
	eq => '0 but true',
	'BigInteger has_coercion_for_type $BiggerInteger eq "0 but true"'
);

ok(
	BigInteger->coercion->has_coercion_for_value([]),
	'BigInteger has_coercion_for_value []',
);

ok(
	BigInteger->coercion->has_coercion_for_value(2),
	'BigInteger has_coercion_for_value 2',
);

ok(
	!BigInteger->coercion->has_coercion_for_value({}),
	'not BigInteger has_coercion_for_value {}',
);

cmp_ok(
	BigInteger->coercion->has_coercion_for_value(200),
	eq => '0 but true',
	'BigInteger has_coercion_for_value 200 eq "0 but true"'
);

is(
	exception { BigInteger->coerce([]) },
	undef,
	"coerce doesn't throw an exception if it can coerce",
);

is(
	exception { BigInteger->coerce({}) },
	undef,
	"coerce doesn't throw an exception if it can't coerce",
);

is(
	exception { BigInteger->assert_coerce([]) },
	undef,
	"assert_coerce doesn't throw an exception if it can coerce",
);

like(
	exception { BigInteger->assert_coerce({}) },
	qr{^Reference \{\} did not pass type constraint "BigInteger"},
	"assert_coerce DOES throw an exception if it can't coerce",
);

isa_ok(
	ArrayRefFromAny,
	'Type::Coercion',
	'ArrayRefFromAny',
);

is_deeply(
	ArrayRefFromAny->coerce(1),
	[1],
	'ArrayRefFromAny coercion works',
);

my $sum1 = ArrayRefFromAny + ArrayRefFromPiped;
is_deeply(
	$sum1->coerce("foo|bar"),
	["foo|bar"],
	"Coercion $sum1 prioritizes ArrayRefFromAny",
);

my $sum2 = ArrayRefFromPiped + ArrayRefFromAny;
is_deeply(
	$sum2->coerce("foo|bar"),
	["foo","bar"],
	"Coercion $sum2 prioritizes ArrayRefFromPiped",
);

my $arr = (ArrayRef) + (ArrayRefFromAny);
is_deeply(
	$arr->coerce("foo|bar"),
	["foo|bar"],
	"Type \$arr coercion works",
);

my $sum3 = ($arr) + (ArrayRefFromPiped);
is_deeply(
	$sum3->coerce("foo|bar"),
	["foo|bar"],
	"Type \$sum3 coercion works",
);

my $sum4 = (ArrayRefFromPiped) + ($arr);
is_deeply(
	$sum4->coerce("foo|bar"),
	["foo","bar"],
	"Type \$sum4 coercion works",
);

done_testing;
