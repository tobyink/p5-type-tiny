=pod

=encoding utf-8

=head1 PURPOSE

Basic tests for B<BoolValue> from L<Types::Common::BoolValues>.

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
use Types::Common::Values qw( BoolValue );

isa_ok(BoolValue, 'Type::Tiny', 'BoolValue');
is(BoolValue->name, 'BoolValue', 'BoolValue has correct name');
is(BoolValue->display_name, 'BoolValue', 'BoolValue has correct display_name');
is(BoolValue->library, 'Types::Common::Values', 'BoolValue knows it is in the Types::Common::Values library');
ok(Types::Common::Values->has_type('BoolValue'), 'Types::Common::Values knows it has type BoolValue');
ok(!BoolValue->deprecated, 'BoolValue is not deprecated');
ok(!BoolValue->is_anon, 'BoolValue is not anonymous');
ok(BoolValue->can_be_inlined, 'BoolValue can be inlined');
is(exception { BoolValue->inline_check(q/$xyz/) }, undef, "Inlining BoolValue doesn't throw an exception");
ok(BoolValue->has_coercion, "BoolValue has a coercion");
ok(!BoolValue->is_parameterizable, "BoolValue isn't parameterizable");
is(BoolValue->type_default->(), !!0, "BoolValue has a type_default");

#
# The @tests array is a list of triples:
#
# 1. Expected result - pass, fail, or xxxx (undefined).
# 2. A description of the BoolValue being tested.
# 3. The BoolValue being tested.
#

my @tests = (
	fail => 'undef'                    => undef,
	pass => 'false'                    => !!0,
	pass => 'true'                     => !!1,
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
	pass => 'builtin::false'           => do { no warnings; builtin->can('false') ? builtin::false() : !!0 },
	pass => 'builtin::true'            => do { no warnings; builtin->can('true') ? builtin::true() : !!1 },
#TESTS
);

while (@tests) {
	my ($expect, $label, $value) = splice(@tests, 0 , 3);
	if ($expect eq 'xxxx') {
		note("UNDEFINED OUTCOME: $label");
	}
	elsif ($expect eq 'pass') {
		should_pass($value, BoolValue, ucfirst("$label should pass BoolValue"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, BoolValue, ucfirst("$label should fail BoolValue"));
	}
	else {
		fail("expected '$expect'?!");
	}
}

should_fail( 0, BoolValue, "Unquoted 0 should fail BoolValue" );
should_fail( 1, BoolValue, "Unquoted 1 should fail BoolValue" );
should_fail( '0', BoolValue, "Quoted 0 should fail BoolValue" );
should_fail( '1', BoolValue, "Quoted 1 should fail BoolValue" );

# Coercions from the looser Bool type constraint
is( BoolValue->assert_coerce( 0 ), !!0 );
is( BoolValue->assert_coerce( 1 ), !!1 );

# This coercion should fail
like( exception { BoolValue->assert_coerce( 2 ) }, qr/Value "2" did not pass type constraint/ );

done_testing;
