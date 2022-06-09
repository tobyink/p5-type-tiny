=pod

=encoding utf-8

=head1 PURPOSE

Check type constraints work with L<Moose>. Checks values that should pass
and should fail; checks error messages.

=head1 DEPENDENCIES

Uses the bundled BiggerLib.pm type library.

Test is skipped if Moose 2.0000 is not available.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
no warnings qw(once);
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::Requires { Moose => 2.0000 };
use Test::Fatal;
use Test::TypeTiny qw( matchfor );

note "The basics";

{
	package Local::Class;
	
	use Moose;
	use BiggerLib -all;
	
	has small => (is => "ro", isa => SmallInteger);
	has big   => (is => "ro", isa => BigInteger);
}

is(
	exception { "Local::Class"->new(small => 9, big => 12) },
	undef,
	"some values that should pass their type constraint",
);

is(
	exception { "Local::Class"->new(small => 100) },
	matchfor(
		'Moose::Exception::ValidationFailedForTypeConstraint',
		qr{^Attribute \(small\) does not pass the type constraint}
	),
	"direct violation of type constraint",
);

is(
	exception { "Local::Class"->new(small => 5.5) },
	matchfor(
		'Moose::Exception::ValidationFailedForTypeConstraint',
		qr{^Attribute \(small\) does not pass the type constraint}
	),
	"violation of parent type constraint",
);

is(
	exception { "Local::Class"->new(small => "five point five") },
	matchfor(
		'Moose::Exception::ValidationFailedForTypeConstraint',
		qr{^Attribute \(small\) does not pass the type constraint}
	),
	"violation of grandparent type constraint",
);

is(
	exception { "Local::Class"->new(small => []) },
	matchfor(
		'Moose::Exception::ValidationFailedForTypeConstraint',
		qr{^Attribute \(small\) does not pass the type constraint}
	),
	"violation of great-grandparent type constraint",
);

note "Coercion...";

my $coercion;
{
	package TmpNS1;
	use Moose::Util::TypeConstraints;
	use Scalar::Util qw(refaddr);
	subtype 'MyInt', as 'Int';
	coerce 'MyInt', from 'ArrayRef', via { scalar(@$_) };
	
	my $orig = find_type_constraint('MyInt');
	my $type = Types::TypeTiny::to_TypeTiny($orig);
	
	::ok($type->has_coercion, 'types converted from Moose retain coercions');
	::is($type->coerce([qw/a b c/]), 3, '... which work');
	
	::is(refaddr($type->moose_type), refaddr($orig), '... refaddr matches');
	::is(refaddr($type->coercion->moose_coercion), refaddr($orig->coercion), '... coercion refaddr matches');
	
	$coercion = $type->coercion;
}

note "Introspection, comparisons, conversions...";

require Types::Standard;
isa_ok(
	Types::Standard::Int(),
	'Class::MOP::Object',
	'Int',
);

isa_ok(
	Types::Standard::ArrayRef(),
	'Moose::Meta::TypeConstraint',
	'ArrayRef',
);

isa_ok(
	Types::Standard::ArrayRef(),
	'Moose::Meta::TypeConstraint::Parameterizable',
	'ArrayRef',
);

isa_ok(
	Types::Standard::ArrayRef()->of(Types::Standard::Int()),
	'Moose::Meta::TypeConstraint',
	'ArrayRef[Int]',
);

isa_ok(
	Types::Standard::ArrayRef()->of(Types::Standard::Int()),
	'Moose::Meta::TypeConstraint::Parameterized',
	'ArrayRef[Int]',
);

isa_ok(
	Types::Standard::ArrayRef() | Types::Standard::Int(),
	'Moose::Meta::TypeConstraint',
	'ArrayRef|Int',
);

isa_ok(
	Types::Standard::ArrayRef() | Types::Standard::Int(),
	'Moose::Meta::TypeConstraint::Union',
	'ArrayRef|Int',
);

isa_ok(
	$coercion,
	'Moose::Meta::TypeCoercion',
	'MyInt->coercion',
);

$coercion = do {
	my $arrayref = Types::Standard::ArrayRef()->plus_coercions(
		Types::Standard::ScalarRef(), sub { [$$_] },
	);
	my $int = Types::Standard::Int()->plus_coercions(
		Types::Standard::Num(), sub { int($_) },
	);
	my $array_or_int = $arrayref | $int;
	$array_or_int->coercion;
};

isa_ok(
	$coercion,
	'Moose::Meta::TypeCoercion',
	'(ArrayRef|Int)->coercion',
);

isa_ok(
	$coercion,
	'Moose::Meta::TypeCoercion::Union',
	'(ArrayRef|Int)->coercion',
);

ok(
	Types::Standard::ArrayRef->moose_type->equals(
		Moose::Util::TypeConstraints::find_type_constraint("ArrayRef")
	),
	"equivalence between Types::Standard types and core Moose types",
);

require Type::Utils;
my $classtype = Type::Utils::class_type(LocalClass => { class => "Local::Class" })->moose_type;
isa_ok(
	$classtype,
	"Moose::Meta::TypeConstraint::Class",
	'$classtype',
);
is(
	$classtype->class,
	"Local::Class",
	"Type::Tiny::Class provides meta information to Moose::Meta::TypeConstraint::Class",
);
isa_ok(
	$classtype->Types::TypeTiny::to_TypeTiny,
	'Type::Tiny::Class',
	'$classtype->Types::TypeTiny::to_TypeTiny',
);

my $roletype = Type::Utils::role_type(LocalRole => { class => "Local::Role" })->moose_type;
isa_ok(
	$roletype,
	"Moose::Meta::TypeConstraint",
	'$roletype',
);
ok(
	!$roletype->isa("Moose::Meta::TypeConstraint::Role"),
	"NB! Type::Tiny::Role does not inflate to Moose::Meta::TypeConstraint::Role because of differing notions as to what constitutes a role.",
);
isa_ok(
	$roletype->Types::TypeTiny::to_TypeTiny,
	'Type::Tiny::Role',
	'$roletype->Types::TypeTiny::to_TypeTiny',
);

my $ducktype = Type::Utils::duck_type(Darkwing => [qw/ foo bar baz /])->moose_type;
isa_ok(
	$ducktype,
	"Moose::Meta::TypeConstraint::DuckType",
	'$ducktype',
);
is_deeply(
	[sort @{$ducktype->methods}],
	[sort qw/ foo bar baz /],
	"Type::Tiny::Duck provides meta information to Moose::Meta::TypeConstraint::DuckType",
);
isa_ok(
	$ducktype->Types::TypeTiny::to_TypeTiny,
	'Type::Tiny::Duck',
	'$ducktype->Types::TypeTiny::to_TypeTiny',
);

my $enumtype = Type::Utils::enum(MyEnum => [qw/ foo bar baz /])->moose_type;
isa_ok(
	$enumtype,
	"Moose::Meta::TypeConstraint::Enum",
	'$classtype',
);
is_deeply(
	[sort @{$enumtype->values}],
	[sort qw/ foo bar baz /],
	"Type::Tiny::Enum provides meta information to Moose::Meta::TypeConstraint::Enum",
);
isa_ok(
	$enumtype->Types::TypeTiny::to_TypeTiny,
	'Type::Tiny::Enum',
	'$enumtype->Types::TypeTiny::to_TypeTiny',
);

my $union = Type::Utils::union(ICU => [$classtype->Types::TypeTiny::to_TypeTiny, $roletype->Types::TypeTiny::to_TypeTiny])->moose_type;
isa_ok(
	$union,
	"Moose::Meta::TypeConstraint::Union",
	'$union',
);
is_deeply(
	[sort @{$union->type_constraints}],
	[sort $classtype, $roletype],
	"Type::Tiny::Union provides meta information to Moose::Meta::TypeConstraint::Union",
);
isa_ok(
	$union->Types::TypeTiny::to_TypeTiny,
	'Type::Tiny::Union',
	'$union->Types::TypeTiny::to_TypeTiny',
);
is(
	[sort @{$union->type_constraints}]->[0]->Types::TypeTiny::to_TypeTiny->{uniq},
	$classtype->Types::TypeTiny::to_TypeTiny->{uniq},
	'$union->type_constraints->[$i]->Types::TypeTiny::to_TypeTiny provides access to underlying Type::Tiny objects'
);

my $intersect = Type::Utils::intersection(Chuck => [$classtype->Types::TypeTiny::to_TypeTiny, $roletype->Types::TypeTiny::to_TypeTiny])->moose_type;
isa_ok(
	$intersect,
	"Moose::Meta::TypeConstraint",
	'$intersect',
);
isa_ok(
	$intersect->Types::TypeTiny::to_TypeTiny,
	'Type::Tiny::Intersection',
	'$intersect->Types::TypeTiny::to_TypeTiny',
);
is(
	Scalar::Util::refaddr( $intersect->Types::TypeTiny::to_TypeTiny ),
	Scalar::Util::refaddr( $intersect->Types::TypeTiny::to_TypeTiny->moose_type->Types::TypeTiny::to_TypeTiny->moose_type->Types::TypeTiny::to_TypeTiny ),
	'round-tripping between ->moose_type and ->Types::TypeTiny::to_TypeTiny preserves reference address'
);

note "Method pass-through";

{
	local *Moose::Meta::TypeConstraint::dummy_1 = sub {
		42;
	};
	local *Moose::Meta::TypeCoercion::dummy_3 = sub {
		666;
	};
	
	is(Types::Standard::Int()->dummy_1, 42, 'method pass-through');
	like(
		exception { Types::Standard::Int()->dummy_2 },
		qr/^Can't locate object method "dummy_2"/,
		'... but not non-existant method',
	);

	ok(
		Types::Standard::Int()->can('dummy_1') && !Types::Standard::Int()->can('dummy_2'),
		'... and `can` works ok',
	);
	
	my $int = Types::Standard::Int()->plus_coercions(Types::Standard::Any(),q[999]);
	is($int->coercion->dummy_3, 666, 'method pass-through for coercions');
	like(
		exception { $int->coercion->dummy_4 },
		qr/^Can't locate object method "dummy_4"/,
		'... but not non-existant method',
	);
	
	ok(
		$int->coercion->can('dummy_3') && !$int->coercion->can('dummy_4'),
		'... and `can` works ok',
	);
}

done_testing;
