=pod

=encoding utf-8

=head1 PURPOSE

Basic tests for B<ScalarRef> from L<Types::Standard>.

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
use Types::Standard qw( ScalarRef );

isa_ok(ScalarRef, 'Type::Tiny', 'ScalarRef');
is(ScalarRef->name, 'ScalarRef', 'ScalarRef has correct name');
is(ScalarRef->display_name, 'ScalarRef', 'ScalarRef has correct display_name');
is(ScalarRef->library, 'Types::Standard', 'ScalarRef knows it is in the Types::Standard library');
ok(Types::Standard->has_type('ScalarRef'), 'Types::Standard knows it has type ScalarRef');
ok(!ScalarRef->deprecated, 'ScalarRef is not deprecated');
ok(!ScalarRef->is_anon, 'ScalarRef is not anonymous');
ok(ScalarRef->can_be_inlined, 'ScalarRef can be inlined');
is(exception { ScalarRef->inline_check(q/$xyz/) }, undef, "Inlining ScalarRef doesn't throw an exception");
ok(!ScalarRef->has_coercion, "ScalarRef doesn't have a coercion");
ok(ScalarRef->is_parameterizable, "ScalarRef is parameterizable");
isnt(ScalarRef->type_default, undef, "ScalarRef has a type_default");
is_deeply(ScalarRef->type_default->(), \undef, "ScalarRef type_default is a reference to undef");

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
	pass => 'a reference to undef'     => do { my $x = undef; \$x },
	pass => 'a reference to false'     => do { my $x = !!0; \$x },
	pass => 'a reference to true'      => do { my $x = !!1; \$x },
	pass => 'a reference to zero'      => do { my $x = 0; \$x },
	pass => 'a reference to one'       => do { my $x = 1; \$x },
	pass => 'a reference to empty string' => do { my $x = ''; \$x },
	pass => 'a reference to random string' => do { my $x = 'abc123'; \$x },
	fail => 'blessed scalarref'        => bless(do { my $x = undef; \$x }, 'SomePkg'),
	fail => 'empty arrayref'           => [],
	fail => 'arrayref with one zero'   => [0],
	fail => 'arrayref of integers'     => [1..10],
	fail => 'arrayref of numbers'      => [1..10, 3.1416],
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
	pass => 'ref to scalarref'         => do { my $x = undef; my $y = \$x; \$y },
	pass => 'ref to arrayref'          => do { my $x = []; \$x },
	pass => 'ref to hashref'           => do { my $x = {}; \$x },
	pass => 'ref to coderef'           => do { my $x = sub { 1 }; \$x },
	pass => 'ref to blessed hashref'   => do { my $x = bless({}, 'SomePkg'); \$x },
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
		should_pass($value, ScalarRef, ucfirst("$label should pass ScalarRef"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, ScalarRef, ucfirst("$label should fail ScalarRef"));
	}
	else {
		fail("expected '$expect'?!");
	}
}

use Scalar::Util qw( refaddr );

my $plain  = ScalarRef;
my $paramd = ScalarRef[];
is(
	refaddr($plain),
	refaddr($paramd),
	'parameterizing with [] has no effect'
);

#
# Parameterization with a type constraint
#

my $IntRef = ScalarRef[ Types::Standard::Int ];
should_pass(\"1", $IntRef);
should_fail(\"1.2", $IntRef);
should_fail(\"abc", $IntRef);

#
# Deep coercion
#

my $Rounded = Types::Standard::Int->plus_coercions(
	Types::Standard::Num, 'int($_)'
);

my $RoundedRef = ScalarRef[ $Rounded ];
should_pass(\"1", $RoundedRef);
should_fail(\"1.2", $RoundedRef);
should_fail(\"abc", $RoundedRef);
ok($RoundedRef->has_coercion);
is_deeply($RoundedRef->coerce(\"3.1"), \"3");

#
# Let's do it with a reference to a reference.
#

my $RoundedArrayRefRef = ScalarRef[ Types::Standard::ArrayRef[$Rounded] ];
should_pass(\[], $RoundedArrayRefRef);
should_pass(\["1"], $RoundedArrayRefRef);
should_fail(\["1.2"], $RoundedArrayRefRef);
should_fail(\["abc"], $RoundedArrayRefRef);
should_fail([], $RoundedArrayRefRef);
should_fail(["1"], $RoundedArrayRefRef);
should_fail(["1.2"], $RoundedArrayRefRef);
should_fail(["abc"], $RoundedArrayRefRef);
ok($RoundedArrayRefRef->has_coercion);
is_deeply($RoundedArrayRefRef->coerce(\["3.1"]), \["3"]);

done_testing;

