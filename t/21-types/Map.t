=pod

=encoding utf-8

=head1 PURPOSE

Basic tests for B<Map> from L<Types::Standard>.

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
use Types::Standard qw( Map );

isa_ok(Map, 'Type::Tiny', 'Map');
is(Map->name, 'Map', 'Map has correct name');
is(Map->display_name, 'Map', 'Map has correct display_name');
is(Map->library, 'Types::Standard', 'Map knows it is in the Types::Standard library');
ok(Types::Standard->has_type('Map'), 'Types::Standard knows it has type Map');
ok(!Map->deprecated, 'Map is not deprecated');
ok(!Map->is_anon, 'Map is not anonymous');
ok(Map->can_be_inlined, 'Map can be inlined');
is(exception { Map->inline_check(q/$xyz/) }, undef, "Inlining Map doesn't throw an exception");
ok(!Map->has_coercion, "Map doesn't have a coercion");
ok(Map->is_parameterizable, "Map is parameterizable");
isnt(Map->type_default, undef, "Map has a type_default");
is_deeply(Map->type_default->(), {}, "Map type_default is {}");

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
	fail => 'empty arrayref'           => [],
	fail => 'arrayref with one zero'   => [0],
	fail => 'arrayref of integers'     => [1..10],
	fail => 'arrayref of numbers'      => [1..10, 3.1416],
	fail => 'blessed arrayref'         => bless([], 'SomePkg'),
	pass => 'empty hashref'            => {},
	pass => 'hashref'                  => { foo => 1 },
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
		should_pass($value, Map, ucfirst("$label should pass Map"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, Map, ucfirst("$label should fail Map"));
	}
	else {
		fail("expected '$expect'?!");
	}
}


#
# Map to constrain keys of hash
#

my $MapWithIntKeys = Map->of( Types::Standard::Int, Types::Standard::Any );

isa_ok($MapWithIntKeys, 'Type::Tiny', '$MapWithIntKeys');
is($MapWithIntKeys->display_name, 'Map[Int,Any]', '$MapWithIntKeys has correct display_name');
ok($MapWithIntKeys->is_anon, '$MapWithIntKeys has no name');
ok($MapWithIntKeys->can_be_inlined, '$MapWithIntKeys can be inlined');
is(exception { $MapWithIntKeys->inline_check(q/$xyz/) }, undef, "Inlining \$MapWithIntKeys doesn't throw an exception");
ok(!$MapWithIntKeys->has_coercion, "\$MapWithIntKeys doesn't have a coercion");
ok(!$MapWithIntKeys->is_parameterizable, "\$MapWithIntKeys is not parameterizable");
isnt($MapWithIntKeys->type_default, undef, "\$MapWithIntKeys has a type_default");
is_deeply($MapWithIntKeys->type_default->(), {}, "\$MapWithIntKeys type_default is {}");
ok_subtype(Types::Standard::HashRef, $MapWithIntKeys);

should_fail( 1,               $MapWithIntKeys );
should_fail( [],              $MapWithIntKeys );
should_pass( {             }, $MapWithIntKeys );
should_fail( { 1.1 =>  []  }, $MapWithIntKeys );
should_pass( { 1   =>  1   }, $MapWithIntKeys );
should_pass( { 1   =>  0   }, $MapWithIntKeys );
should_pass( { 1   => -1   }, $MapWithIntKeys );
should_pass( { 1   => \1   }, $MapWithIntKeys );
should_pass( { -1  => -1   }, $MapWithIntKeys );
should_fail( { foo =>  1   }, $MapWithIntKeys );


#
# Map has these cool extra methods...
#

ok(
	$MapWithIntKeys->my_hashref_allows_key('1234'),
	"my_hashref_allows_key('1234')",
);

ok(
	!$MapWithIntKeys->my_hashref_allows_key('abc'),
	"!my_hashref_allows_key('abc')",
);


#
# Map to constrain values of hash.
# Basically like HashRef[Int]
#

my $HashOfInts = Map->of( Types::Standard::Any, Types::Standard::Int );

isa_ok($HashOfInts, 'Type::Tiny', '$HashOfInts');
is($HashOfInts->display_name, 'Map[Any,Int]', '$HashOfInts has correct display_name');
ok($HashOfInts->is_anon, '$HashOfInts has no name');
ok($HashOfInts->can_be_inlined, '$HashOfInts can be inlined');
is(exception { $HashOfInts->inline_check(q/$xyz/) }, undef, "Inlining \$HashOfInts doesn't throw an exception");
ok(!$HashOfInts->has_coercion, "\$HashOfInts doesn't have a coercion");
ok(!$HashOfInts->is_parameterizable, "\$HashOfInts is not parameterizable");
ok_subtype(Types::Standard::HashRef, $HashOfInts);

should_fail( 1,               $HashOfInts );
should_fail( [],              $HashOfInts );
should_pass( {             }, $HashOfInts );
should_fail( { foo =>  []  }, $HashOfInts );
should_fail( { foo =>  1.1 }, $HashOfInts );
should_pass( { foo =>  1   }, $HashOfInts );
should_pass( { foo =>  0   }, $HashOfInts );
should_pass( { foo => -1   }, $HashOfInts );
should_fail( { foo => \1   }, $HashOfInts );
should_fail( { 123 => \1   }, $HashOfInts );
should_pass( { 123 =>  1   }, $HashOfInts );
should_pass( { foo =>  1, bar =>  2 }, $HashOfInts );
should_fail( { foo =>  1, bar => [] }, $HashOfInts );


#
# More Map extra methods...
#

ok(
	$HashOfInts->my_hashref_allows_key('foo'),
	"my_hashref_allows_key('foo')",
);

ok(
	$HashOfInts->my_hashref_allows_value('foo', 1234),
	"my_hashref_allows_value('foo', 1234)",
);

ok(
	! $HashOfInts->my_hashref_allows_value('foo', qr//),
	"!my_hashref_allows_value('foo', qr//)",
);


#
# Map has deep coercions
#

my $Rounded = Types::Standard::Int->plus_coercions( Types::Standard::Num, q{ int($_) } );
my $HashOfRounded = Map->of( $Rounded, $Rounded );

use Scalar::Util qw(refaddr);

do {
	my $orig    = { 3 => 4 };
	my $coerced = $HashOfRounded->coerce($orig);
	
	is( refaddr($orig), refaddr($coerced), "just returned orig unchanged" );
};

do {
	my $orig    = { 3.1 => 4.2 };
	my $coerced = $HashOfRounded->coerce($orig); # {3=>4}
	
	isnt( refaddr($orig), refaddr($coerced), "coercion happened" );
	is($coerced->{3}, 4, "... and data looks good");
	should_pass($coerced, $HashOfRounded, "... and now passes type constraint");
};

do {
	my $orig    = { foo => [] };
	my $coerced = $HashOfRounded->coerce($orig);
	
	is( refaddr($orig), refaddr($coerced), "coercion failed, so orig was returned" );
	should_fail($coerced, $HashOfRounded);
};


#
# Parameterization fails with bad parameters
#

do {
	my $e = exception { Map[qw(hello world)] };
	like($e, qr/expected to be a type constraint/, 'bad parameters');
};


done_testing;

