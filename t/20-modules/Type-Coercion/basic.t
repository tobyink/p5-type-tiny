=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Coercion works.

=head1 DEPENDENCIES

Uses the bundled BiggerLib.pm type library.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

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

my $sum1 = 'Type::Coercion'->add(ArrayRefFromAny, ArrayRefFromPiped);
is_deeply(
	$sum1->coerce("foo|bar"),
	["foo|bar"],
	"Coercion $sum1 prioritizes ArrayRefFromAny",
);

my $sum2 = 'Type::Coercion'->add(ArrayRefFromPiped, ArrayRefFromAny);
is_deeply(
	$sum2->coerce("foo|bar"),
	["foo","bar"],
	"Coercion $sum2 prioritizes ArrayRefFromPiped",
);

my $arr = ArrayRef->plus_fallback_coercions(ArrayRefFromAny);
is_deeply(
	$arr->coerce("foo|bar"),
	["foo|bar"],
	"Type \$arr coercion works",
);

my $sum3 = $arr->plus_fallback_coercions(ArrayRefFromPiped);
is_deeply(
	$sum3->coerce("foo|bar"),
	["foo|bar"],
	"Type \$sum3 coercion works",
);

my $sum4 = $arr->plus_coercions(ArrayRefFromPiped);
is_deeply(
	$sum4->coerce("foo|bar"),
	["foo","bar"],
	"Type \$sum4 coercion works",
);

use Test::TypeTiny;

my $arrayref_from_piped = ArrayRef->plus_coercions(ArrayRefFromPiped);
my $coercibles          = $arrayref_from_piped->coercibles;
should_pass([],      $coercibles);
should_pass('1|2|3', $coercibles);
should_fail({},      $coercibles);

should_pass([],      ArrayRef->coercibles);
should_fail('1|2|3', ArrayRef->coercibles);
should_fail({},      ArrayRef->coercibles);

is($arrayref_from_piped->coercibles, $arrayref_from_piped->coercibles, '$arrayref_from_piped->coercibles == $arrayref_from_piped->coercibles');

# ensure that add_type_coercion can handle Type::Coercions
subtest 'add a Type::Coercion to a Type::Coercion' => sub {
	
	my $coercion = Type::Coercion->new;
	ok(
		!$coercion->has_coercion_for_type( Str ),
		"empty coercion can't coerce a Str"
	);
	
	is( exception { $coercion->add_type_coercions( ArrayRefFromPiped ) },
	undef, "add a coercion from Str" );
	
	ok(
		$coercion->has_coercion_for_type( Str ),
		"check that coercion was added"
	);
	
	# now see if coercion actually works
	my $arrayref_from_piped = ArrayRef->plus_coercions($coercion);
	my $coercibles          = $arrayref_from_piped->coercibles;
	should_pass('1|2|3', $coercibles, "can coerce from a Str");
};


done_testing;
