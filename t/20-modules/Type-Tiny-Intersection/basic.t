=pod

=encoding utf-8

=head1 PURPOSE

Checks intersection type constraints work.

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
use Type::Utils qw( intersection );

{ my $x; sub FooBarAndDoesQuux () { $x ||= intersection(FooBarAndDoesQuux => [FooBar, DoesQuux]) } }

isa_ok(
	FooBarAndDoesQuux,
	'Type::Tiny::Intersection',
	'FooBarAndDoesQuux',
);

isa_ok(
	FooBarAndDoesQuux->[0],
	'Type::Tiny::Class',
	'FooBarAndDoesQuux->[0]',
);

isa_ok(
	FooBarAndDoesQuux->[1],
	'Type::Tiny::Role',
	'FooBarAndDoesQuux->[1]',
);

is(
	FooBarAndDoesQuux."",
	'FooBar&DoesQuux',
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

should_fail("Foo::Bar"->new, FooBarAndDoesQuux);
should_pass("Foo::Baz"->new, FooBarAndDoesQuux);
should_fail($something, FooBarAndDoesQuux);

my $something_else = bless [] => do {
	package Something::Else;
	sub DOES {
		return 1 if $_[1] eq 'Else';
		$_[0]->isa($_[0]);
	}
	__PACKAGE__;
};

should_fail($something_else, FooBarAndDoesQuux);
should_fail("Foo::Bar", FooBarAndDoesQuux);
should_fail("Foo::Baz", FooBarAndDoesQuux);

require Types::Standard;
my $reftype_array = Types::Standard::Ref["ARRAY"];
{ my $x; sub NotherSect () { $x ||= intersection(NotherUnion => [FooBarAndDoesQuux, $reftype_array]) } }

is(
	scalar @{+NotherSect},
	3,
	"intersections don't get unnecessarily deep",
);

note NotherSect->inline_check('$X');

should_pass(bless([], "Foo::Baz"), NotherSect);
should_fail(bless({}, "Foo::Baz"), NotherSect);

my $SmallEven = SmallInteger & sub { $_ % 2 == 0 };

isa_ok($SmallEven, "Type::Tiny::Intersection");
ok(!$SmallEven->can_be_inlined, "not ($SmallEven)->can_be_inlined");
should_pass(2, $SmallEven);
should_fail(20, $SmallEven);
should_fail(3, $SmallEven);

done_testing;
