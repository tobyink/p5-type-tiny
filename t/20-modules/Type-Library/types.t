=pod

=encoding utf-8

=head1 PURPOSE

Checks that the type functions exported by a type library work as expected.

=head1 DEPENDENCIES

Uses the bundled DemoLib.pm type library.

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

use DemoLib -types;

isa_ok String, "Type::Tiny", "String";
isa_ok Number, "Type::Tiny", "Number";
isa_ok Integer, "Type::Tiny", "Integer";

isa_ok DemoLib::String, "Type::Tiny", "DemoLib::String";
isa_ok DemoLib::Number, "Type::Tiny", "DemoLib::Number";
isa_ok DemoLib::Integer, "Type::Tiny", "DemoLib::Integer";

is(String."", "String", "String has correct stringification");
is(Number."", "Number", "Number has correct stringification");
is(Integer."", "Integer", "Integer has correct stringification");

is(DemoLib::String."", "String", "DemoLib::String has correct stringification");
is(DemoLib::Number."", "Number", "DemoLib::Number has correct stringification");
is(DemoLib::Integer."", "Integer", "DemoLib::Integer has correct stringification");

is(
	exception { Integer->(5) },
	undef,
	"coderef overload (with value that should pass type constraint) does not die",
);

is(
	Integer->(5),
	5,
	"coderef overload returns correct value",
);

like(
	exception { Integer->(5.5) },
	qr{^Value "5\.5" did not pass type constraint "Integer"},
	"coderef overload (value that should fail type constraint) dies",
);

use DemoLib String => {
	-prefix  => "foo",
	-as      => "bar",
	-suffix  => "baz",
};

is(foobarbaz->qualified_name, "DemoLib::String", "Sub::Exporter-style export renaming");

ok(
	Integer eq Integer,
	'eq works',
);

use Types::Standard qw(ArrayRef Int);

my $int          = Int;
my $arrayref     = ArrayRef;
my $arrayref_int = ArrayRef[Int];

is_deeply(
	[ 1, 2, Int,  3, 4 ],
	[ 1, 2, $int, 3, 4 ],
	'type constant in list context',
);

is_deeply(
	[ 1, 2, ArrayRef,  3, 4 ],
	[ 1, 2, $arrayref, 3, 4 ],
	'parameterizable type constant in list context',
);

is_deeply(
	[ 1, 2, ArrayRef[Int], 3, 4 ],
	[ 1, 2, $arrayref_int, 3, 4 ],
	'parameterized type constant in list context',
);

done_testing;
