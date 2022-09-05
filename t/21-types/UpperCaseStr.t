=pod

=encoding utf-8

=head1 PURPOSE

Basic tests for B<UpperCaseStr> from L<Types::Common::String>.

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
use Types::Common::String qw( UpperCaseStr );

isa_ok(UpperCaseStr, 'Type::Tiny', 'UpperCaseStr');
is(UpperCaseStr->name, 'UpperCaseStr', 'UpperCaseStr has correct name');
is(UpperCaseStr->display_name, 'UpperCaseStr', 'UpperCaseStr has correct display_name');
is(UpperCaseStr->library, 'Types::Common::String', 'UpperCaseStr knows it is in the Types::Common::String library');
ok(Types::Common::String->has_type('UpperCaseStr'), 'Types::Common::String knows it has type UpperCaseStr');
ok(!UpperCaseStr->deprecated, 'UpperCaseStr is not deprecated');
ok(!UpperCaseStr->is_anon, 'UpperCaseStr is not anonymous');
ok(UpperCaseStr->can_be_inlined, 'UpperCaseStr can be inlined');
is(exception { UpperCaseStr->inline_check(q/$xyz/) }, undef, "Inlining UpperCaseStr doesn't throw an exception");
ok(UpperCaseStr->has_coercion, "UpperCaseStr has a coercion");
ok(!UpperCaseStr->is_parameterizable, "UpperCaseStr isn't parameterizable");
is(UpperCaseStr->type_default, undef, "UpperCaseStr has no type_default");

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
	pass => 'true'                     => !!1,
	pass => 'zero'                     =>  0,
	pass => 'one'                      =>  1,
	pass => 'negative one'             => -1,
	pass => 'non integer'              =>  3.1416,
	fail => 'empty string'             => '',
	pass => 'whitespace'               => ' ',
	pass => 'line break'               => "\n",
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
		should_pass($value, UpperCaseStr, ucfirst("$label should pass UpperCaseStr"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, UpperCaseStr, ucfirst("$label should fail UpperCaseStr"));
	}
	else {
		fail("expected '$expect'?!");
	}
}

# Cyrillic Small Letter Zhe
should_fail("\x{0436}", UpperCaseStr);

# Cyrillic Capital Letter Zhe
should_pass("\x{0416}", UpperCaseStr);

#
# These examples are probably obvious.
#

should_pass('ABCDEF', UpperCaseStr);
should_pass('ABC123', UpperCaseStr);
should_fail('abc123', UpperCaseStr);
should_fail('abcdef', UpperCaseStr);

#
# A string with only non-letter characters passes.
#

should_pass('123456', UpperCaseStr);
should_pass(' ', UpperCaseStr);

#
# But the empty string fails.
# (Which is weird, but consistent with MooseX::Types::Common::String.)
#

should_fail('', UpperCaseStr);

#
# Can coerce from lowercase strings.
#

is(UpperCaseStr->coerce('abc123'), 'ABC123', 'coercion success');

#
# Won't even attempt to coerce non-strings.
#

use Scalar::Util qw( refaddr );
my $arr      = [];
my $coerced  = UpperCaseStr->coerce($arr);
is(refaddr($coerced), refaddr($arr), 'does not coerce non-strings');

done_testing;

