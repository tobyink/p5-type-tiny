=pod

=encoding utf-8

=head1 PURPOSE

Basic tests for B<HashRef> from L<Types::Standard>.

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
use Types::Standard qw( HashRef );

isa_ok(HashRef, 'Type::Tiny', 'HashRef');
is(HashRef->name, 'HashRef', 'HashRef has correct name');
is(HashRef->display_name, 'HashRef', 'HashRef has correct display_name');
is(HashRef->library, 'Types::Standard', 'HashRef knows it is in the Types::Standard library');
ok(Types::Standard->has_type('HashRef'), 'Types::Standard knows it has type HashRef');
ok(!HashRef->deprecated, 'HashRef is not deprecated');
ok(!HashRef->is_anon, 'HashRef is not anonymous');
ok(HashRef->can_be_inlined, 'HashRef can be inlined');
is(exception { HashRef->inline_check(q/$xyz/) }, undef, "Inlining HashRef doesn't throw an exception");
ok(!HashRef->has_coercion, "HashRef doesn't have a coercion");
ok(HashRef->is_parameterizable, "HashRef is parameterizable");
isnt(HashRef->type_default, undef, "HashRef has a type_default");
is_deeply(HashRef->type_default->(), {}, "HashRef type_default is {}");

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
		should_pass($value, HashRef, ucfirst("$label should pass HashRef"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, HashRef, ucfirst("$label should fail HashRef"));
	}
	else {
		fail("expected '$expect'?!");
	}
}

#
# HashRef is parameterizable
#

my $HashOfInts = HashRef->of( Types::Standard::Int );

isa_ok($HashOfInts, 'Type::Tiny', '$HashOfInts');
is($HashOfInts->display_name, 'HashRef[Int]', '$HashOfInts has correct display_name');
ok($HashOfInts->is_anon, '$HashOfInts has no name');
ok($HashOfInts->can_be_inlined, '$HashOfInts can be inlined');
is(exception { $HashOfInts->inline_check(q/$xyz/) }, undef, "Inlining \$HashOfInts doesn't throw an exception");
ok(!$HashOfInts->has_coercion, "\$HashOfInts doesn't have a coercion");
ok(!$HashOfInts->is_parameterizable, "\$HashOfInts is not parameterizable");
isnt($HashOfInts->type_default, undef, "\$HashOfInts has a type_default");
is_deeply($HashOfInts->type_default->(), {}, "\$HashOfInts type_default is {}");
ok_subtype(HashRef, $HashOfInts);

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
# HashRef has these cool extra methods...
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
# HashRef has deep coercions
#

my $Rounded = Types::Standard::Int->plus_coercions( Types::Standard::Num, q{ int($_) } );
my $HashOfRounded = HashRef->of( $Rounded );

isa_ok($HashOfRounded, 'Type::Tiny', '$HashOfRounded');
is($HashOfRounded->display_name, 'HashRef[Int]', '$HashOfRounded has correct display_name');
ok($HashOfRounded->is_anon, '$HashOfRounded has no name');
ok($HashOfRounded->can_be_inlined, '$HashOfRounded can be inlined');
is(exception { $HashOfRounded->inline_check(q/$xyz/) }, undef, "Inlining \$HashOfRounded doesn't throw an exception");
ok($HashOfRounded->has_coercion, "\$HashOfRounded has a coercion");
ok($HashOfRounded->coercion->has_coercion_for_type(HashRef), '$HashRefOfRounded can coerce from HashRef');
ok($HashOfRounded->coercion->has_coercion_for_type(HashRef->of(Types::Standard::Num)), '$HashRefOfRounded can coerce from HashRef[Num]');
ok(!$HashOfRounded->is_parameterizable, "\$HashOfRounded is not parameterizable");
ok_subtype(HashRef, $HashOfRounded);

should_fail( 1,               $HashOfRounded );
should_fail( [],              $HashOfRounded );
should_pass( {             }, $HashOfRounded );
should_fail( { foo =>  []  }, $HashOfRounded );
should_fail( { foo =>  1.1 }, $HashOfRounded );
should_pass( { foo =>  1   }, $HashOfRounded );
should_pass( { foo =>  0   }, $HashOfRounded );
should_pass( { foo => -1   }, $HashOfRounded );
should_fail( { foo => \1   }, $HashOfRounded );
should_fail( { 123 => \1   }, $HashOfRounded );
should_pass( { 123 =>  1   }, $HashOfRounded );
should_pass( { foo =>  1, bar =>  2 }, $HashOfRounded );
should_fail( { foo =>  1, bar => [] }, $HashOfRounded );

use Scalar::Util qw(refaddr);

do {
	my $orig    = { foo => 42 };
	my $coerced = $HashOfRounded->coerce($orig);
	
	is( refaddr($orig), refaddr($coerced), "just returned orig unchanged" );
};

do {
	my $orig    = { foo => 42.1 };
	my $coerced = $HashOfRounded->coerce($orig);
	
	isnt( refaddr($orig), refaddr($coerced), "coercion happened" );
	is($coerced->{foo}, 42, "... and data looks good");
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
	my $e = exception { HashRef['hello world'] };
	like($e, qr/expected to be a type constraint/, 'can only be parameterized with another type');
};

# this should probably issue an exception, but doesn't currently...

#do {
#	my $e = exception { HashRef[HashRef, HashRef] };
#	isnt($e, undef);
#};

done_testing;

