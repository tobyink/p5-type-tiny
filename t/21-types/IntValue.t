=pod

=encoding utf-8

=head1 PURPOSE

Basic tests for B<IntValue> from L<Types::Common::IntValues>.

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
use Types::Common::Values qw( IntValue );

isa_ok(IntValue, 'Type::Tiny', 'IntValue');
is(IntValue->name, 'IntValue', 'IntValue has correct name');
is(IntValue->display_name, 'IntValue', 'IntValue has correct display_name');
is(IntValue->library, 'Types::Common::Values', 'IntValue knows it is in the Types::Common::Values library');
ok(Types::Common::Values->has_type('IntValue'), 'Types::Common::Values knows it has type IntValue');
ok(!IntValue->deprecated, 'IntValue is not deprecated');
ok(!IntValue->is_anon, 'IntValue is not anonymous');
ok(IntValue->can_be_inlined, 'IntValue can be inlined');
is(exception { IntValue->inline_check(q/$xyz/) }, undef, "Inlining IntValue doesn't throw an exception");
ok(IntValue->has_coercion, "IntValue has a coercion");
ok(!IntValue->is_parameterizable, "IntValue isn't parameterizable");
is(IntValue->type_default->(), 0, "IntValue has a type_default");

#
# The @tests array is a list of triples:
#
# 1. Expected result - pass, fail, or xxxx (undefined).
# 2. A description of the IntValue being tested.
# 3. The IntValue being tested.
#

my @tests = (
	fail => 'undef'                    => undef,
	fail => 'false'                    => !!0,
	fail => 'true'                     => !!1,
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
		should_pass($value, IntValue, ucfirst("$label should pass IntValue"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, IntValue, ucfirst("$label should fail IntValue"));
	}
	else {
		fail("expected '$expect'?!");
	}
}

# Quoted numbers fail
should_fail( '0', IntValue, "Quoted 0 should fail IntValue" );
should_fail( '1', IntValue, "Quoted 1 should fail IntValue" );
should_fail( '999', IntValue, "Quoted 999 should fail IntValue" );
should_fail( '9.9', IntValue, "Quoted 9.9 should fail IntValue" );

# Coercions from the looser Int type constraint
is( IntValue->assert_coerce( '0' ), 0 );
is( IntValue->assert_coerce( '1' ), 1 );
is( IntValue->assert_coerce( '999' ), 999 );

# This coercion should fail
like( exception { IntValue->assert_coerce( '9.9' ) }, qr/Value "9.9" did not pass type constraint/ );

done_testing;
