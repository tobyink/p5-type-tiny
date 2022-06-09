=pod

=encoding utf-8

=head1 PURPOSE

Checks various values against the type constraints from Types::Standard.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( . ./t ../inc ./inc );

use Test::More;
use Test::Fatal;
use Test::TypeTiny;

use Types::Standard -all;

is(Num->library, "Types::Standard", "->library method");

my $var = 123;
should_pass(\$var, ScalarRef);
should_pass([], ArrayRef);
should_pass(+{}, HashRef);
should_pass(sub {0}, CodeRef);
should_pass(\*STDOUT, GlobRef);
should_pass(\(\"Hello"), Ref);
should_pass(\*STDOUT, FileHandle);
should_pass(qr{x}, RegexpRef);
should_pass(1, Str);
should_pass(1, Num);
should_pass(1, Int);
should_pass(1, Defined);
should_pass(1, Value);
should_pass(undef, Undef);
should_pass(undef, Item);
should_pass(undef, Any);
should_pass('Type::Tiny', ClassName);
should_pass('Type::Library', RoleName);

should_pass(undef, Bool);
should_pass('', Bool);
should_pass(0, Bool);
should_pass(1, Bool);
should_fail(7, Bool);
should_pass(\(\"Hello"), ScalarRef);
should_fail('Type::Tiny', RoleName);

should_fail([], Str);
should_fail([], Num);
should_fail([], Int);
should_pass("4x4", Str);
should_fail("4x4", Num);
should_fail("4.2", Int);

should_fail(undef, Str);
should_fail(undef, Num);
should_fail(undef, Int);
should_fail(undef, Defined);
should_fail(undef, Value);

{
	package Local::Class1;
	use strict;
}

{
	no warnings 'once';
	$Local::Class2::VERSION = 0.001;
	@Local::Class3::ISA     = qw(UNIVERSAL);
	@Local::Dummy1::FOO     = qw(UNIVERSAL);
}

{
	package Local::Class4;
	sub XYZ () { 1 }
}

should_fail(undef, ClassName);
should_fail([], ClassName);
should_pass("Local::Class$_", ClassName) for 2..4;
should_fail("Local::Dummy1", ClassName);

should_pass([], ArrayRef[Int]);
should_pass([1,2,3], ArrayRef[Int]);
should_fail([1.1,2,3], ArrayRef[Int]);
should_fail([1,2,3.1], ArrayRef[Int]);
should_fail([[]], ArrayRef[Int]);
should_pass([[3]], ArrayRef[ArrayRef[Int]]);
should_fail([["A"]], ArrayRef[ArrayRef[Int]]);

my $deep = ArrayRef[HashRef[ArrayRef[HashRef[Int]]]];
ok($deep->can_be_inlined, "$deep can be inlined");

should_pass([{foo1=>[{bar=>1}]},{foo2=>[{baz=>2}]}], $deep);
should_pass([{foo1=>[{bar=>1}]},{foo2=>[]}], $deep);
should_fail([{foo1=>[{bar=>1}]},{foo2=>[2]}], $deep);

should_pass(undef, Maybe[Int]);
should_pass(123, Maybe[Int]);
should_fail(1.3, Maybe[Int]);

my $i = 1;
my $f = 1.1;
my $s = "Hello";
should_pass(\$s, ScalarRef[Str]);
should_pass(\$f, ScalarRef[Str]);
should_pass(\$i, ScalarRef[Str]);
should_fail(\$s, ScalarRef[Num]);
should_pass(\$f, ScalarRef[Num]);
should_pass(\$i, ScalarRef[Num]);
should_fail(\$s, ScalarRef[Int]);
should_fail(\$f, ScalarRef[Int]);
should_pass(\$i, ScalarRef[Int]);

should_pass(bless([], "Local::Class4"), Ref["ARRAY"]);
should_pass(bless({}, "Local::Class4"), Ref["HASH"]);
should_pass([], Ref["ARRAY"]);
should_pass({}, Ref["HASH"]);
should_fail(bless([], "Local::Class4"), Ref["HASH"]);
should_fail(bless({}, "Local::Class4"), Ref["ARRAY"]);
should_fail([], Ref["HASH"]);
should_fail({}, Ref["ARRAY"]);

like(
	exception { ArrayRef["Int"] },
	qr{^Parameter to ArrayRef\[\`a\] expected to be a type constraint; got Int},
	qq{ArrayRef["Int"] is not a valid type constraint},
);

like(
	exception { HashRef[[]] },
	qr{^Parameter to HashRef\[\`a\] expected to be a type constraint; got ARRAY},
	qq{HashRef[[]] is not a valid type constraint},
);

like(
	exception { ScalarRef[undef] },
	qr{^Parameter to ScalarRef\[\`a\] expected to be a type constraint; got},
	qq{ScalarRef[undef] is not a valid type constraint},
);

like(
	exception { Ref[{}] },
	qr{^Parameter to Ref\[\`a\] expected to be a Perl ref type; got HASH},
	qq{Ref[{}] is not a valid type constraint},
);

SKIP: {
	skip "requires Perl 5.8", 3 if $] < 5.008;
	
	ok(
		!!Num->check("Inf") == !Types::Standard::STRICTNUM,
		"'Inf' passes Num unless Types::Standard::STRICTNUM",
	);

	ok(
		!!Num->check("-Inf") == !Types::Standard::STRICTNUM,
		"'-Inf' passes Num unless Types::Standard::STRICTNUM",
	);

	ok(
		!!Num->check("Nan") == !Types::Standard::STRICTNUM,
		"'Nan' passes Num unless Types::Standard::STRICTNUM",
	);
}

ok(
	!!Num->check("0.") == !Types::Standard::STRICTNUM,
	"'0.' passes Num unless Types::Standard::STRICTNUM",
);

ok_subtype(Any, Item);

done_testing;
