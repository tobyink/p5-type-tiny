=pod

=encoding utf-8

=head1 PURPOSE

Basic tests for B<ArrayLike> from L<Types::TypeTiny>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::TypeTiny;
use Types::TypeTiny qw( ArrayLike );

isa_ok(ArrayLike, 'Type::Tiny', 'ArrayLike');
is(ArrayLike->name, 'ArrayLike', 'ArrayLike has correct name');
is(ArrayLike->display_name, 'ArrayLike', 'ArrayLike has correct display_name');
is(ArrayLike->library, 'Types::TypeTiny', 'ArrayLike knows it is in the Types::TypeTiny library');
ok(Types::TypeTiny->has_type('ArrayLike'), 'Types::TypeTiny knows it has type ArrayLike');
ok(!ArrayLike->deprecated, 'ArrayLike is not deprecated');
ok(!ArrayLike->is_anon, 'ArrayLike is not anonymous');
ok(ArrayLike->can_be_inlined, 'ArrayLike can be inlined');
is(exception { ArrayLike->inline_check(q/$xyz/) }, undef, "Inlining ArrayLike doesn't throw an exception");
ok(!ArrayLike->has_coercion, "ArrayLike doesn't have a coercion");
ok(ArrayLike->is_parameterizable, "ArrayLike is parameterizable");
isnt(ArrayLike->type_default, undef, "ArrayLike has a type_default");
is_deeply(ArrayLike->type_default->(), [], "ArrayLike type_default is []");

#
# The @tests array is a list of triples:
#
# 1. Expected result - pass, fail, or xxxx (undefined).
# 2. A description of the value being tested.
# 3. The value being tested.
#

my @tests = (
	fail => 'undef'                    => undef,
	fail => 'false'                    => !!0,
	fail => 'true'                     => !!1,
	fail => 'zero'                     =>  0,
	fail => 'one'                      =>  1,
	fail => 'negative one'             => -1,
	fail => 'non integer'              =>  3.1416,
	fail => 'empty string'             => '',
	fail => 'whitespace'               => ' ',
	fail => 'line break'               => "\n",
	fail => 'random string'            => 'abc123',
	fail => 'loaded package name'      => 'Type::Tiny',
	fail => 'unloaded package name'    => 'This::Has::Probably::Not::Been::Loaded',
	fail => 'a reference to undef'     => do { my $x = undef; \$x },
	fail => 'a reference to false'     => do { my $x = !!0; \$x },
	fail => 'a reference to true'      => do { my $x = !!1; \$x },
	fail => 'a reference to zero'      => do { my $x = 0; \$x },
	fail => 'a reference to one'       => do { my $x = 1; \$x },
	fail => 'a reference to empty string' => do { my $x = ''; \$x },
	fail => 'a reference to random string' => do { my $x = 'abc123'; \$x },
	fail => 'blessed scalarref'        => bless(do { my $x = undef; \$x }, 'SomePkg'),
	pass => 'empty arrayref'           => [],
	pass => 'arrayref with one zero'   => [0],
	pass => 'arrayref of integers'     => [1..10],
	pass => 'arrayref of numbers'      => [1..10, 3.1416],
	fail => 'blessed arrayref'         => bless([], 'SomePkg'),
	fail => 'empty hashref'            => {},
	fail => 'hashref'                  => { foo => 1 },
	fail => 'blessed hashref'          => bless({}, 'SomePkg'),
	fail => 'coderef'                  => sub { 1 },
	fail => 'blessed coderef'          => bless(sub { 1 }, 'SomePkg'),
	fail => 'glob'                     => do { no warnings 'once'; *SOMETHING },
	fail => 'globref'                  => do { no warnings 'once'; my $x = *SOMETHING; \$x },
	fail => 'blessed globref'          => bless(do { no warnings 'once'; my $x = *SOMETHING; \$x }, 'SomePkg'),
	fail => 'regexp'                   => qr/./,
	fail => 'blessed regexp'           => bless(qr/./, 'SomePkg'),
	fail => 'filehandle'               => do { open my $x, '<', $0 or die; $x },
	fail => 'filehandle object'        => do { require IO::File; 'IO::File'->new($0, 'r') },
	fail => 'ref to scalarref'         => do { my $x = undef; my $y = \$x; \$y },
	fail => 'ref to arrayref'          => do { my $x = []; \$x },
	fail => 'ref to hashref'           => do { my $x = {}; \$x },
	fail => 'ref to coderef'           => do { my $x = sub { 1 }; \$x },
	fail => 'ref to blessed hashref'   => do { my $x = bless({}, 'SomePkg'); \$x },
	fail => 'object stringifying to ""' => do { package Local::OL::StringEmpty; use overload q[""] => sub { "" }; bless [] },
	fail => 'object stringifying to "1"' => do { package Local::OL::StringOne; use overload q[""] => sub { "1" }; bless [] },
	fail => 'object numifying to 0'    => do { package Local::OL::NumZero; use overload q[0+] => sub { 0 }; bless [] },
	fail => 'object numifying to 1'    => do { package Local::OL::NumOne; use overload q[0+] => sub { 1 }; bless [] },
	pass => 'object overloading arrayref' => do { package Local::OL::Array; use overload q[@{}] => sub { $_[0]{array} }; bless {array=>[]} },
	fail => 'object overloading hashref' => do { package Local::OL::Hash; use overload q[%{}] => sub { $_[0][0] }; bless [{}] },
	fail => 'object overloading coderef' => do { package Local::OL::Code; use overload q[&{}] => sub { $_[0][0] }; bless [sub { 1 }] },
#TESTS
);

while (@tests) {
	my ($expect, $label, $value) = splice(@tests, 0 , 3);
	if ($expect eq 'xxxx') {
		note("UNDEFINED OUTCOME: $label");
	}
	elsif ($expect eq 'pass') {
		should_pass($value, ArrayLike, ucfirst("$label should pass ArrayLike"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, ArrayLike, ucfirst("$label should fail ArrayLike"));
	}
	else {
		fail("expected '$expect'?!");
	}
}

#
# Parameterizable
#

use Types::Standard ();

my $ArrayOfInt = ArrayLike[ Types::Standard::Int() ];

ok( $ArrayOfInt->can_be_inlined );

should_pass(
	[1,2,3],
	$ArrayOfInt,
);

should_pass(
	bless({ array=>[1,2,3] }, 'Local::OL::Array'),
	$ArrayOfInt,
);

should_fail(
	[undef,2,3],
	$ArrayOfInt,
);

should_fail(
	bless({ array=>[undef,2,3] }, 'Local::OL::Array'),
	$ArrayOfInt,
);

my $ArrayOfRounded = ArrayLike[
	Types::Standard::Int()->plus_coercions(
		Types::Standard::Num(), => q{ int($_) },
	)
];

is_deeply(
	$ArrayOfRounded->coerce([1.1, 2, 3]),
	[1,2,3],
);

# Note that because of coercion, the object overloading @{}
# is now a plain old arrayref.
is_deeply(
	$ArrayOfRounded->coerce(bless({ array=>[1.1,2,3] }, 'Local::OL::Array')),
	[1,2,3],
);

is_deeply(
	$ArrayOfRounded->coerce([1.1, undef, 3]),
	[1.1,undef,3],  # cannot be coerced, so returned unchanged
);

# can't use is_deeply because object doesn't overload eq
# but the idea is because the coercion fails, the original
# object gets returned unchanged
ok(
	Scalar::Util::blessed( $ArrayOfRounded->coerce(bless({ array=>[1.1,undef,3] }, 'Local::OL::Array')) ),
);

done_testing;

