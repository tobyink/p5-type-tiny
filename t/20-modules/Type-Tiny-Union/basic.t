=pod

=encoding utf-8

=head1 PURPOSE

Checks union type constraints work.

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
use Test::TypeTiny;

use BiggerLib qw( :types );
use Type::Utils qw( union class_type );

{ my $x; sub FooBarOrDoesQuux () { $x ||= union(FooBarOrDoesQuux => [FooBar, DoesQuux]) } }

isa_ok(
	FooBarOrDoesQuux,
	'Type::Tiny::Union',
	'FooBarOrDoesQuux',
);

isa_ok(
	FooBarOrDoesQuux->[0],
	'Type::Tiny::Class',
	'FooBarOrDoesQuux->[0]',
);

isa_ok(
	FooBarOrDoesQuux->[1],
	'Type::Tiny::Role',
	'FooBarOrDoesQuux->[1]',
);

is(
	FooBarOrDoesQuux."",
	'FooBar|DoesQuux',
	'stringification good',
);

my $something = bless [] => do {
	package Something;
	sub DOES {
		return 1 if $_[1] eq 'Quux';
		$_[0]->isa($_[0]);
	}
	__PACKAGE__;
};

should_pass("Foo::Bar"->new, FooBarOrDoesQuux);
should_pass("Foo::Baz"->new, FooBarOrDoesQuux);
should_pass($something, FooBarOrDoesQuux);

my $something_else = bless [] => do {
	package Something::Else;
	sub DOES {
		return 1 if $_[1] eq 'Else';
		$_[0]->isa($_[0]);
	}
	__PACKAGE__;
};

should_fail($something_else, FooBarOrDoesQuux);
should_fail("Foo::Bar", FooBarOrDoesQuux);
should_fail("Foo::Baz", FooBarOrDoesQuux);

{ my $x; sub NotherUnion () { $x ||= union(NotherUnion => [BigInteger, FooBarOrDoesQuux, SmallInteger]) } }

is(
	scalar @{+NotherUnion},
	4,
	"unions don't get unnecessarily deep",
);

{ package Local::A }
{ package Local::B }
{ package Local::C }
{ package Local::A::A; our @ISA = qw(Local::A) }
{ package Local::A::B; our @ISA = qw(Local::A) }
{ package Local::A::AB; our @ISA = qw(Local::A::A Local::A::B) }
{ package Local::A::X; our @ISA = qw(Local::A)  }

my $c1 = union [
	class_type({ class => "Local::A::AB" }),
	class_type({ class => "Local::A::X" }),
];

ok(
	$c1->parent == class_type({ class => "Local::A" }),
	"can climb up parents of union type constraints to find best common ancestor",
);

my $c2 = union [
	class_type({ class => "Local::A" }),
	class_type({ class => "Local::B" }),
	class_type({ class => "Local::C" }),
];

ok(
	$c2->parent == Types::Standard::Object(),
	"can climb up parents of union type constraints to find best common ancestor (again)",
);

is(
	$c2->find_type_for( bless({}, 'Local::B') )->class,
	'Local::B',
	'Union find_type_for',
);

is(
	$c2->find_type_for( bless({}, 'Local::A::A') )->class,
	'Local::A',
	'Union find_type_for (less obvious)',
);

is(
	$c2->find_type_for( bless({}, 'Local::A::AB') )->class,
	'Local::A',
	'Union find_type_for (ambiguous)',
);

is(
	$c2->find_type_for( bless({}, 'Local::D') ),
	undef,
	'Union find_type_for (none)',
);

ok(
	(FooBar|DoesQuux)==(DoesQuux|FooBar),
	'Union equals',
);

ok(
	(FooBar|DoesQuux)!=(DoesQuux|SmallInteger),
	'Union not equals',
);

done_testing;
