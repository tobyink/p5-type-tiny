=pod

=encoding utf-8

=head1 PURPOSE

Basic tests for B<NumValue> from L<Types::Common::NumValues>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2026 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::TypeTiny;
use Test::Requires qw(boolean);
use Types::Common::Values qw( NumValue );

isa_ok(NumValue, 'Type::Tiny', 'NumValue');
is(NumValue->name, 'NumValue', 'NumValue has correct name');
is(NumValue->display_name, 'NumValue', 'NumValue has correct display_name');
is(NumValue->library, 'Types::Common::Values', 'NumValue knows it is in the Types::Common::Values library');
ok(Types::Common::Values->has_type('NumValue'), 'Types::Common::Values knows it has type NumValue');
ok(!NumValue->deprecated, 'NumValue is not deprecated');
ok(!NumValue->is_anon, 'NumValue is not anonymous');
ok(NumValue->can_be_inlined, 'NumValue can be inlined');
is(exception { NumValue->inline_check(q/$xyz/) }, undef, "Inlining NumValue doesn't throw an exception");
ok(NumValue->has_coercion, "NumValue has a coercion");
ok(!NumValue->is_parameterizable, "NumValue isn't parameterizable");
is(NumValue->type_default->(), 0, "NumValue has a type_default");

#
# The @tests array is a list of triples:
#
# 1. Expected result - pass, fail, or xxxx (undefined).
# 2. A description of the NumValue being tested.
# 3. The NumValue being tested.
#

my @tests = (
	fail => 'undef'                    => undef,
	fail => 'false'                    => !!0,
	fail => 'true'                     => !!1,
	pass => 'zero'                     =>  0,
	pass => 'one'                      =>  1,
	pass => 'negative one'             => -1,
	pass => 'non integer'              =>  3.1416,
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
	fail => 'object booling to false'  => do { package Local::OL::BoolFalse; use overload q[bool] => sub { 0 }; bless [] },
	fail => 'object booling to true'   => do { package Local::OL::BoolTrue;  use overload q[bool] => sub { 1 }; bless [] },
	fail => 'boolean::false'           => boolean::false,
	fail => 'boolean::true'            => boolean::true,
	fail => 'builtin::false'           => do { no warnings; builtin->can('false') ? builtin::false() : !!0 },
	fail => 'builtin::true'            => do { no warnings; builtin->can('true') ? builtin::true() : !!1 },
#TESTS
);

while (@tests) {
	my ($expect, $label, $value) = splice(@tests, 0 , 3);
	if ($expect eq 'xxxx') {
		note("UNDEFINED OUTCOME: $label");
	}
	elsif ($expect eq 'pass') {
		should_pass($value, NumValue, ucfirst("$label should pass NumValue"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, NumValue, ucfirst("$label should fail NumValue"));
	}
	else {
		fail("expected '$expect'?!");
	}
}

# Quoted numbers fail
should_fail( '0', NumValue, "Quoted 0 should fail NumValue" );
should_fail( '1', NumValue, "Quoted 1 should fail NumValue" );
should_fail( '999', NumValue, "Quoted 999 should fail NumValue" );
should_fail( '9.9', NumValue, "Quoted 9.9 should fail NumValue" );

# Coercions from the looser Num type constraint
is( NumValue->assert_coerce( '0' ), 0 );
is( NumValue->assert_coerce( '1' ), 1 );
is( NumValue->assert_coerce( '999' ), 999 );

# Don't strictly check equality in this test in case of floating point errors
ok( abs( NumValue->assert_coerce( '9.9' ) - 9.9 ) < 0.001 );

done_testing;
