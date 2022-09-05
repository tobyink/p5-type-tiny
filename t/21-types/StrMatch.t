=pod

=encoding utf-8

=head1 PURPOSE

Basic tests for B<StrMatch> from L<Types::Standard>.

=head1 SEE ALSO

StrMatch-more.t

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
use Types::Standard qw( StrMatch );

isa_ok(StrMatch, 'Type::Tiny', 'StrMatch');
is(StrMatch->name, 'StrMatch', 'StrMatch has correct name');
is(StrMatch->display_name, 'StrMatch', 'StrMatch has correct display_name');
is(StrMatch->library, 'Types::Standard', 'StrMatch knows it is in the Types::Standard library');
ok(Types::Standard->has_type('StrMatch'), 'Types::Standard knows it has type StrMatch');
ok(!StrMatch->deprecated, 'StrMatch is not deprecated');
ok(!StrMatch->is_anon, 'StrMatch is not anonymous');
ok(StrMatch->can_be_inlined, 'StrMatch can be inlined');
is(exception { StrMatch->inline_check(q/$xyz/) }, undef, "Inlining StrMatch doesn't throw an exception");
ok(!StrMatch->has_coercion, "StrMatch doesn't have a coercion");
ok(StrMatch->is_parameterizable, "StrMatch is parameterizable");
isnt(StrMatch->type_default, undef, "StrMatch has a type_default");
is(StrMatch->type_default->(), '', "StrMatch type_default is the empty string");

#
# The @tests array is a list of triples:
#
# 1. Expected result - pass, fail, or xxxx (undefined).
# 2. A description of the value being tested.
# 3. The value being tested.
#

my @tests = (
	fail => 'undef'                    => undef,
	pass => 'false'                    => !!0,
	pass => 'true'                     => !!1,
	pass => 'zero'                     =>  0,
	pass => 'one'                      =>  1,
	pass => 'negative one'             => -1,
	pass => 'non integer'              =>  3.1416,
	pass => 'empty string'             => '',
	pass => 'whitespace'               => ' ',
	pass => 'line break'               => "\n",
	pass => 'random string'            => 'abc123',
	pass => 'loaded package name'      => 'Type::Tiny',
	pass => 'unloaded package name'    => 'This::Has::Probably::Not::Been::Loaded',
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
		should_pass($value, StrMatch, ucfirst("$label should pass StrMatch"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, StrMatch, ucfirst("$label should fail StrMatch"));
	}
	else {
		fail("expected '$expect'?!");
	}
}

#
# This should be pretty obvious.
#

my $type1 = StrMatch[ qr/a[b]c/i ];

should_pass('abc', $type1);
should_pass('ABC', $type1);
should_pass('fooabcbar', $type1);
should_pass('fooABCbar', $type1);
should_fail('a[b]c', $type1);

is($type1->type_default, undef, "$type1 has no type_default");

#
# StrMatch only accepts true strings.
#

{
	package Local::OL::Stringy;
	use overload q[""] => sub { ${$_[0]} };
	sub new { my ($class, $str) = @_; bless(\$str, $class) }
}

my $abc_obj = Local::OL::Stringy->new('abc');
is("$abc_obj", "abc");
should_fail($abc_obj, $type1);

#
# But you can do this to create a type accepting a overloaded objects
# that stringify to a string matching $type1.
#

use Types::Standard qw(Overload);
my $type2 = Overload->of(q[""])->stringifies_to($type1);
should_pass($abc_obj, $type2);
should_fail('abc', $type2);  # ... though that doesn't accept real strings.

#
# Union type constraint to the rescue!
#

my $type3 = $type1 | $type2;
should_pass($abc_obj, $type3);
should_pass('abc', $type3);

#
# Okay, it was fun looking at overloaded objects, but let's look at
# something else...
#

use Types::Standard qw( +Num Enum Tuple );

my $metric_distance = StrMatch[
	# Strings must match this regexp
	qr/^(\S+) (\S+)$/,
	# Captures get checked against this constraint
	Tuple[
		Num,
		Enum[qw/ mm cm m km /],
	],
];

should_pass('1 km', $metric_distance);
should_pass('-1.6 cm', $metric_distance);
should_fail('xyz km', $metric_distance);
should_fail('7 miles', $metric_distance);
should_fail('7 km   ', $metric_distance);

#
# You could implement it like this instead because a coderef
# returning a boolean can be used like a type constraint.
#

$metric_distance = StrMatch[
	# Strings must match this regexp
	qr/^(\S+) (\S+)$/,
	sub {
		my $captures = shift;
		return !!0 unless is_Num $captures->[0];
		return !!1 if $captures->[1] eq 'mm';
		return !!1 if $captures->[1] eq 'cm';
		return !!1 if $captures->[1] eq 'm';
		return !!1 if $captures->[1] eq 'km';
		return !!0;
	}
];

should_pass('1 km', $metric_distance);
should_pass('-1.6 cm', $metric_distance);
should_fail('xyz km', $metric_distance);
should_fail('7 miles', $metric_distance);
should_fail('7 km   ', $metric_distance);

done_testing;

