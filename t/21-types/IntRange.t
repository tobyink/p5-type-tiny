=pod

=encoding utf-8

=head1 PURPOSE

Basic tests for B<IntRange> from L<Types::Common::Numeric>.

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
use Types::Common::Numeric qw( IntRange );

isa_ok(IntRange, 'Type::Tiny', 'IntRange');
is(IntRange->name, 'IntRange', 'IntRange has correct name');
is(IntRange->display_name, 'IntRange', 'IntRange has correct display_name');
is(IntRange->library, 'Types::Common::Numeric', 'IntRange knows it is in the Types::Common::Numeric library');
ok(Types::Common::Numeric->has_type('IntRange'), 'Types::Common::Numeric knows it has type IntRange');
ok(!IntRange->deprecated, 'IntRange is not deprecated');
ok(!IntRange->is_anon, 'IntRange is not anonymous');
ok(IntRange->can_be_inlined, 'IntRange can be inlined');
is(exception { IntRange->inline_check(q/$xyz/) }, undef, "Inlining IntRange doesn't throw an exception");
ok(!IntRange->has_coercion, "IntRange doesn't have a coercion");
ok(IntRange->is_parameterizable, "IntRange is parameterizable");
isnt(IntRange->type_default, undef, "IntRange has a type_default");
is(IntRange->type_default->(), 0, "IntRange type_default is zero");

#
# The @tests array is a list of triples:
#
# 1. Expected result - pass, fail, or xxxx (undefined).
# 2. A description of the value being tested.
# 3. The value being tested.
#

my @tests = (
	fail => 'undef'                    => undef,
	xxxx => 'false'                    => !!0,
	pass => 'true'                     => !!1,
	pass => 'zero'                     =>  0,
	pass => 'one'                      =>  1,
	pass => 'negative one'             => -1,
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
		should_pass($value, IntRange, ucfirst("$label should pass IntRange"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, IntRange, ucfirst("$label should fail IntRange"));
	}
	else {
		fail("expected '$expect'?!");
	}
}

#
# If there's one parameter, it is an inclusive minimum.
#

my $IntRange_2 = IntRange[2];

should_fail(-2, $IntRange_2);
should_fail(-1, $IntRange_2);
should_fail( 0, $IntRange_2);
should_fail( 1, $IntRange_2);
should_pass( 2, $IntRange_2);
should_pass( 3, $IntRange_2);
should_pass( 4, $IntRange_2);
should_pass( 5, $IntRange_2);
should_pass( 6, $IntRange_2);
should_fail(3.1416, $IntRange_2);
should_fail([], $IntRange_2);

is($IntRange_2->type_default, undef, "$IntRange_2 has no type_default");

#
# If there's two parameters, they are inclusive minimum and maximum.
#

my $IntRange_2_4 = IntRange[2, 4];

should_fail(-2, $IntRange_2_4);
should_fail(-1, $IntRange_2_4);
should_fail( 0, $IntRange_2_4);
should_fail( 1, $IntRange_2_4);
should_pass( 2, $IntRange_2_4);
should_pass( 3, $IntRange_2_4);
should_pass( 4, $IntRange_2_4);
should_fail( 5, $IntRange_2_4);
should_fail( 6, $IntRange_2_4);
should_fail(3.1416, $IntRange_2_4);
should_fail([], $IntRange_2_4);

#
# Can set an exclusive minimum and maximum.
#

my $IntRange_2_4_ex = IntRange[2, 4, 1, 1];

should_fail(-2, $IntRange_2_4_ex);
should_fail(-1, $IntRange_2_4_ex);
should_fail( 0, $IntRange_2_4_ex);
should_fail( 1, $IntRange_2_4_ex);
should_fail( 2, $IntRange_2_4_ex);
should_pass( 3, $IntRange_2_4_ex);
should_fail( 4, $IntRange_2_4_ex);
should_fail( 5, $IntRange_2_4_ex);
should_fail( 6, $IntRange_2_4_ex);
should_fail(3.1416, $IntRange_2_4_ex);
should_fail([], $IntRange_2_4_ex);

my $e = exception { IntRange[1.1] };
like($e, qr/min must be/, 'bad parameter');

done_testing;

