=pod

=encoding utf-8

=head1 PURPOSE

Basic tests for B<ArrayRef> from L<Types::Standard>.

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
use Types::Standard qw( ArrayRef );

isa_ok(ArrayRef, 'Type::Tiny', 'ArrayRef');
is(ArrayRef->name, 'ArrayRef', 'ArrayRef has correct name');
is(ArrayRef->display_name, 'ArrayRef', 'ArrayRef has correct display_name');
is(ArrayRef->library, 'Types::Standard', 'ArrayRef knows it is in the Types::Standard library');
ok(Types::Standard->has_type('ArrayRef'), 'Types::Standard knows it has type ArrayRef');
ok(!ArrayRef->deprecated, 'ArrayRef is not deprecated');
ok(!ArrayRef->is_anon, 'ArrayRef is not anonymous');
ok(ArrayRef->can_be_inlined, 'ArrayRef can be inlined');
is(exception { ArrayRef->inline_check(q/$xyz/) }, undef, "Inlining ArrayRef doesn't throw an exception");
ok(!ArrayRef->has_coercion, "ArrayRef doesn't have a coercion");
ok(ArrayRef->is_parameterizable, "ArrayRef is parameterizable");
isnt(ArrayRef->type_default, undef, "ArrayRef has a type_default");
is_deeply(ArrayRef->type_default->(), [], "ArrayRef type_default is []");

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
		should_pass($value, ArrayRef, ucfirst("$label should pass ArrayRef"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, ArrayRef, ucfirst("$label should fail ArrayRef"));
	}
	else {
		fail("expected '$expect'?!");
	}
}


#
# ArrayRef is parameterizable
#

my $ArrayOfInts = ArrayRef->of( Types::Standard::Int );

isa_ok($ArrayOfInts, 'Type::Tiny', '$ArrayOfInts');
is($ArrayOfInts->display_name, 'ArrayRef[Int]', '$ArrayOfInts has correct display_name');
ok($ArrayOfInts->is_anon, '$ArrayOfInts has no name');
ok($ArrayOfInts->can_be_inlined, '$ArrayOfInts can be inlined');
is(exception { $ArrayOfInts->inline_check(q/$xyz/) }, undef, "Inlining \$ArrayOfInts doesn't throw an exception");
ok(!$ArrayOfInts->has_coercion, "\$ArrayOfInts doesn't have a coercion");
ok(!$ArrayOfInts->is_parameterizable, "\$ArrayOfInts is not parameterizable");
isnt($ArrayOfInts->type_default, undef, "\$ArrayOfInts has a type_default");
is_deeply($ArrayOfInts->type_default->(), [], "\$ArrayOfInts type_default is []");

ok_subtype(ArrayRef, $ArrayOfInts);

should_fail( 1,        $ArrayOfInts );
should_fail( {},       $ArrayOfInts );
should_pass( [      ], $ArrayOfInts );
should_fail( [ []   ], $ArrayOfInts );
should_fail( [  1.1 ], $ArrayOfInts );
should_pass( [  1   ], $ArrayOfInts );
should_pass( [  0   ], $ArrayOfInts );
should_pass( [ -1   ], $ArrayOfInts );
should_fail( [ \1   ], $ArrayOfInts );
should_pass( [  1,   2 ], $ArrayOfInts );
should_fail( [  1,  [] ], $ArrayOfInts );

use Scalar::Util qw( refaddr );

my $plain  = ArrayRef;
my $paramd = ArrayRef[];
is(
	refaddr($plain),
	refaddr($paramd),
	'parameterizing with [] has no effect'
);

my $p1 = ArrayRef[Types::Standard::Int];
my $p2 = ArrayRef[Types::Standard::Int];
is(refaddr($p1), refaddr($p2), 'parameterizing is cached');


#
# ArrayRef can accept a second parameter.
#

my $ArrayOfAtLeastTwoInts = ArrayRef->of( Types::Standard::Int, 2 );

should_fail( 1,        $ArrayOfAtLeastTwoInts );
should_fail( {},       $ArrayOfAtLeastTwoInts );
should_fail( [      ], $ArrayOfAtLeastTwoInts );
should_fail( [ []   ], $ArrayOfAtLeastTwoInts );
should_fail( [  1.1 ], $ArrayOfAtLeastTwoInts );
should_fail( [  1   ], $ArrayOfAtLeastTwoInts );
should_fail( [  0   ], $ArrayOfAtLeastTwoInts );
should_fail( [ -1   ], $ArrayOfAtLeastTwoInts );
should_fail( [ \1   ], $ArrayOfAtLeastTwoInts );
should_pass( [  1,   2 ], $ArrayOfAtLeastTwoInts );
should_fail( [  1,  [] ], $ArrayOfAtLeastTwoInts );
should_pass( [  1,  -1 ], $ArrayOfAtLeastTwoInts );
should_pass( [  1 .. 9 ], $ArrayOfAtLeastTwoInts );

is($ArrayOfAtLeastTwoInts->type_default, undef, "\$ArrayOfAtLeastTwoInts has no type_default");


#
# ArrayRef has deep coercions
#

my $Rounded = Types::Standard::Int->plus_coercions( Types::Standard::Num, q{ int($_) } );
my $ArrayOfRounded = ArrayRef->of( $Rounded );

isa_ok($ArrayOfRounded, 'Type::Tiny', '$ArrayOfRounded');
is($ArrayOfRounded->display_name, 'ArrayRef[Int]', '$ArrayOfRounded has correct display_name');
ok($ArrayOfRounded->is_anon, '$ArrayOfRounded has no name');
ok($ArrayOfRounded->can_be_inlined, '$ArrayOfRounded can be inlined');
is(exception { $ArrayOfRounded->inline_check(q/$xyz/) }, undef, "Inlining \$ArrayOfRounded doesn't throw an exception");
ok($ArrayOfRounded->has_coercion, "\$ArrayOfRounded has a coercion");
ok($ArrayOfRounded->coercion->has_coercion_for_type(ArrayRef), '$ArrayRefOfRounded can coerce from ArrayRef');
ok($ArrayOfRounded->coercion->has_coercion_for_type(ArrayRef->of(Types::Standard::Num)), '$ArrayRefOfRounded can coerce from ArrayRef[Num]');
ok(!$ArrayOfRounded->is_parameterizable, "\$ArrayOfRounded is not parameterizable");
ok_subtype(ArrayRef, $ArrayOfRounded);

should_fail( 1,        $ArrayOfRounded );
should_fail( {},       $ArrayOfRounded );
should_pass( [      ], $ArrayOfRounded );
should_fail( [ []   ], $ArrayOfRounded );
should_fail( [  1.1 ], $ArrayOfRounded );
should_pass( [  1   ], $ArrayOfRounded );
should_pass( [  0   ], $ArrayOfRounded );
should_pass( [ -1   ], $ArrayOfRounded );
should_fail( [ \1   ], $ArrayOfRounded );
should_pass( [  1,   2 ], $ArrayOfRounded );
should_fail( [  1,  [] ], $ArrayOfRounded );

do {
	my $orig    = [ 42 ];
	my $coerced = $ArrayOfRounded->coerce($orig);
	
	is( refaddr($orig), refaddr($coerced), "just returned orig unchanged" );
};

do {
	my $orig    = [ 42.1 ];
	my $coerced = $ArrayOfRounded->coerce($orig);
	
	isnt( refaddr($orig), refaddr($coerced), "coercion happened" );
	is($coerced->[0], 42, "... and data looks good");
	should_pass($coerced, $ArrayOfRounded, "... and now passes type constraint");
};

do {
	my $orig    = [ [] ];
	my $coerced = $ArrayOfRounded->coerce($orig);
	
	is( refaddr($orig), refaddr($coerced), "coercion failed, so orig was returned" );
	should_fail($coerced, $ArrayOfRounded);
};

done_testing;
