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

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::Requires { Moose => 2.0000 };
use Test::Fatal;

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

like(
	exception { "Local::Class"->new(small => 100) },
	qr{^Attribute \(small\) does not pass the type constraint},
	"direct violation of type constraint",
);

like(
	exception { "Local::Class"->new(small => 5.5) },
	qr{^Attribute \(small\) does not pass the type constraint},
	"violation of parent type constraint",
);

like(
	exception { "Local::Class"->new(small => "five point five") },
	qr{^Attribute \(small\) does not pass the type constraint},
	"violation of grandparent type constraint",
);

like(
	exception { "Local::Class"->new(small => []) },
	qr{^Attribute \(small\) does not pass the type constraint},
	"violation of great-grandparent type constraint",
);

require Types::Standard;
ok(
	Types::Standard::Num->moose_type->equals(
		Moose::Util::TypeConstraints::find_type_constraint("Num")
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
	$classtype->tt_type,
	'Type::Tiny::Class',
	'$classtype->tt_type',
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
	$roletype->tt_type,
	'Type::Tiny::Role',
	'$roletype->tt_type',
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
	$ducktype->tt_type,
	'Type::Tiny::Duck',
	'$ducktype->tt_type',
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
	$enumtype->tt_type,
	'Type::Tiny::Enum',
	'$enumtype->tt_type',
);

my $union = Type::Utils::union(ICU => [$classtype->tt_type, $roletype->tt_type])->moose_type;
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
	$union->tt_type,
	'Type::Tiny::Union',
	'$union->tt_type',
);
is(
	[sort @{$union->type_constraints}]->[0]->tt_type->{uniq},
	$classtype->tt_type->{uniq},
	'$union->type_constraints->[$i]->tt_type provides access to underlying Type::Tiny objects'
);

my $intersect = Type::Utils::intersection(Chuck => [$classtype->tt_type, $roletype->tt_type])->moose_type;
isa_ok(
	$intersect,
	"Moose::Meta::TypeConstraint",
	'$intersect',
);
isa_ok(
	$intersect->tt_type,
	'Type::Tiny::Intersection',
	'$intersect->tt_type',
);

done_testing;
