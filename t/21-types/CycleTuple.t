=pod

=encoding utf-8

=head1 PURPOSE

Basic tests for B<CycleTuple> from L<Types::Standard>.

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
use Types::Standard qw( CycleTuple );

isa_ok(CycleTuple, 'Type::Tiny', 'CycleTuple');
is(CycleTuple->name, 'CycleTuple', 'CycleTuple has correct name');
is(CycleTuple->display_name, 'CycleTuple', 'CycleTuple has correct display_name');
is(CycleTuple->library, 'Types::Standard', 'CycleTuple knows it is in the Types::Standard library');
ok(Types::Standard->has_type('CycleTuple'), 'Types::Standard knows it has type CycleTuple');
ok(!CycleTuple->deprecated, 'CycleTuple is not deprecated');
ok(!CycleTuple->is_anon, 'CycleTuple is not anonymous');
ok(CycleTuple->can_be_inlined, 'CycleTuple can be inlined');
is(exception { CycleTuple->inline_check(q/$xyz/) }, undef, "Inlining CycleTuple doesn't throw an exception");
ok(!CycleTuple->has_coercion, "CycleTuple doesn't have a coercion");
ok(CycleTuple->is_parameterizable, "CycleTuple is parameterizable");
isnt(CycleTuple->type_default, undef, "CycleTuple has a type_default");
is_deeply(CycleTuple->type_default->(), [], "CycleTuple type_default is []");

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
	fail => 'object overloading arrayref' => do { package Local::OL::Array; use overload q[@{}] => sub { $_[0]{array} }; bless {array=>[]} },
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
		should_pass($value, CycleTuple, ucfirst("$label should pass CycleTuple"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, CycleTuple, ucfirst("$label should fail CycleTuple"));
	}
	else {
		fail("expected '$expect'?!");
	}
}

#
# Basic example.
#

my $type1 = CycleTuple[
	Types::Standard::Int,
	Types::Standard::HashRef,
	Types::Standard::RegexpRef,
];

should_pass([ 1,{},qr//                                        ], $type1);
should_pass([ 1,{},qr// => 2,{},qr//                           ], $type1);
should_pass([ 1,{},qr// => 2,{},qr// => 3,{},qr//              ], $type1);
should_pass([ 1,{},qr// => 2,{},qr// => 3,{},qr// => 4,{},qr// ], $type1);
should_fail([ 1,{},qr// => 2,{},qr// => 3,{},qr// => 4,{}      ], $type1); # fails because missing slot
should_fail([ 1,{},qr// => 2,{},qr// => 3,{},qr// => 4,{},[]   ], $type1); # fails because bad value in slot

#
# Explanations
#

my $explanation = join "\n", @{ $type1->validate_explain([1], '$VAL') };
like($explanation, qr/expects a multiple of 3 values in the array/);
like($explanation, qr/1 values? found/);

my $explanation2 = join "\n", @{ $type1->validate_explain([1,undef,qr//], '$VAL') };
like($explanation2, qr/constrains value at index 1 of array with "HashRef"/);

#
# Empty arrayref
#

use Types::Standard qw( ArrayRef Any );

# An empty arrayref is okay
should_pass( [], $type1 );

# Here's one way to make sure the arrayref isn't empty
should_fail( [], $type1->where('@$_>0') );

# Here's another way
should_fail( [], ArrayRef[Any,1] & $type1 );


#
# Optional is not allowed.
#

my $e = exception {
	CycleTuple[
		Types::Standard::Optional[
			Types::Standard::Int,
		],
	]
};
like($e, qr/cannot be optional/, 'correct exception');


#
# Deep coercions
#

my $type2 = CycleTuple[
	Types::Standard::Int->plus_coercions(
		Types::Standard::Num, q{ int($_) },
	),
	Types::Standard::HashRef,
];

my $coerced = $type2->coerce(
	[ 1.1,{} => 2.1,{} => 3.1,{} => 4.1,{} ]
);

is_deeply(
	$coerced,
	[ 1,{} => 2,{} => 3,{} => 4,{} ],
	'coercion worked',
);

done_testing;

