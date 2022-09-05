=pod

=encoding utf-8

=head1 PURPOSE

Basic tests for B<Bool> from L<Types::Standard>.

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
use Types::Standard qw( Bool );

isa_ok(Bool, 'Type::Tiny', 'Bool');
is(Bool->name, 'Bool', 'Bool has correct name');
is(Bool->display_name, 'Bool', 'Bool has correct display_name');
is(Bool->library, 'Types::Standard', 'Bool knows it is in the Types::Standard library');
ok(Types::Standard->has_type('Bool'), 'Types::Standard knows it has type Bool');
ok(!Bool->deprecated, 'Bool is not deprecated');
ok(!Bool->is_anon, 'Bool is not anonymous');
ok(Bool->can_be_inlined, 'Bool can be inlined');
is(exception { Bool->inline_check(q/$xyz/) }, undef, "Inlining Bool doesn't throw an exception");
ok(Bool->has_coercion, "Bool has a coercion");
ok(!Bool->is_parameterizable, "Bool isn't parameterizable");
isnt(Bool->type_default, undef, "Bool has a type_default");
is(Bool->type_default->(), !!0, "Bool type_default is false");

#
# The @tests array is a list of triples:
#
# 1. Expected result - pass, fail, or xxxx (undefined).
# 2. A description of the value being tested.
# 3. The value being tested.
#

my @tests = (
	pass => 'undef'                    => undef,
	pass => 'false'                    => !!0,
	pass => 'true'                     => !!1,
	pass => 'zero'                     =>  0,
	pass => 'one'                      =>  1,
	fail => 'negative one'             => -1,
	fail => 'non integer'              =>  3.1416,
	pass => 'empty string'             => '',
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
		should_pass($value, Bool, ucfirst("$label should pass Bool"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, Bool, ucfirst("$label should fail Bool"));
	}
	else {
		fail("expected '$expect'?!");
	}
}

#
# Bool has coercions from everything.
#

my @tests2 = (
	false => 'undef'                    => undef,
	false => 'false'                    => !!0,
	true  => 'true'                     => !!1,
	false => 'zero'                     =>  0,
	true  => 'one'                      =>  1,
	true  => 'negative one'             => -1,
	true  => 'non integer'              =>  3.1416,
	false => 'empty string'             => '',
	true  => 'whitespace'               => ' ',
	true  => 'line break'               => "\n",
	true  => 'random string'            => 'abc123',
	true  => 'loaded package name'      => 'Type::Tiny',
	true  => 'unloaded package name'    => 'This::Has::Probably::Not::Been::Loaded',
	true  => 'a reference to undef'     => do { my $x = undef; \$x },
	true  => 'a reference to false'     => do { my $x = !!0; \$x },
	true  => 'a reference to true'      => do { my $x = !!1; \$x },
	true  => 'a reference to zero'      => do { my $x = 0; \$x },
	true  => 'a reference to one'       => do { my $x = 1; \$x },
	true  => 'a reference to empty string' => do { my $x = ''; \$x },
	true  => 'a reference to random string' => do { my $x = 'abc123'; \$x },
	true  => 'blessed scalarref'        => bless(do { my $x = undef; \$x }, 'SomePkg'),
	true  => 'empty arrayref'           => [],
	true  => 'arrayref with one zero'   => [0],
	true  => 'arrayref of integers'     => [1..10],
	true  => 'arrayref of numbers'      => [1..10, 3.1416],
	true  => 'blessed arrayref'         => bless([], 'SomePkg'),
	true  => 'empty hashref'            => {},
	true  => 'hashref'                  => { foo => 1 },
	true  => 'blessed hashref'          => bless({}, 'SomePkg'),
	true  => 'coderef'                  => sub { 1 },
	true  => 'blessed coderef'          => bless(sub { 1 }, 'SomePkg'),
	true  => 'glob'                     => do { no warnings 'once'; *SOMETHING },
	true  => 'globref'                  => do { no warnings 'once'; my $x = *SOMETHING; \$x },
	true  => 'blessed globref'          => bless(do { no warnings 'once'; my $x = *SOMETHING; \$x }, 'SomePkg'),
	true  => 'regexp'                   => qr/./,
	true  => 'blessed regexp'           => bless(qr/./, 'SomePkg'),
	true  => 'filehandle'               => do { open my $x, '<', $0 or die; $x },
	true  => 'filehandle object'        => do { require IO::File; 'IO::File'->new($0, 'r') },
	true  => 'ref to scalarref'         => do { my $x = undef; my $y = \$x; \$y },
	true  => 'ref to arrayref'          => do { my $x = []; \$x },
	true  => 'ref to hashref'           => do { my $x = {}; \$x },
	true  => 'ref to coderef'           => do { my $x = sub { 1 }; \$x },
	true  => 'ref to blessed hashref'   => do { my $x = bless({}, 'SomePkg'); \$x },
	true  => 'object stringifying to ""' => do { package Local::OL::StringEmpty; use overload q[bool] => sub { !!1 }; bless [] },
	true  => 'object stringifying to "1"' => do { package Local::OL::StringOne; use overload q[bool] => sub { !!1 }; bless [] },
	false => 'object boolifying to false' => do { package Local::OL::BoolFalse; use overload q[bool] => sub { !!0 }; bless [] },
	true  => 'object boolifying to true' => do { package Local::OL::BoolTrue; use overload q[bool] => sub { !!1 }; bless [] },
	true  => 'object numifying to 0'    => do { package Local::OL::NumZero; use overload q[bool] => sub { !!1 }; bless [] },
	true  => 'object numifying to 1'    => do { package Local::OL::NumOne; use overload q[bool] => sub { !!1 }; bless [] },
	true  => 'object overloading arrayref' => do { package Local::OL::Array; use overload q[bool] => sub { !!1 }; bless {array=>[]} },
	true  => 'object overloading hashref' => do { package Local::OL::Hash; use overload q[bool] => sub { !!1 }; bless [{}] },
	true  => 'object overloading coderef' => do { package Local::OL::Code; use overload q[bool] => sub { !!1 }; bless [sub { 1 }] },
);

while (@tests2) {
	my ($expect, $label, $value) = splice(@tests2, 0 , 3);
	my $coerced;
	my $exception = exception { $coerced = Bool->assert_coerce($value) };
	is($exception, undef, "Bool coerced $label successfully");
	if ($expect eq 'true') {
		ok($coerced, "Bool coerced $label to true");
	}
	elsif ($expect eq 'false') {
		ok(!$coerced, "Bool coerced $label to false");
	}
	else {
		fail("expected '$expect'?!");
	}
}

#
# Bool and JSON::PP is worth showing.
#

if (eval { require JSON::PP }) {
	my $JSON_true  = JSON::PP::true();
	my $JSON_false = JSON::PP::false();
	
	my @values;
	my $exception = exception {
		@values = map Bool->assert_coerce($_), $JSON_true, $JSON_false;
	};
	
	should_fail($JSON_true,  Bool, "JSON::PP::true does NOT pass Bool");
	should_fail($JSON_false, Bool, "JSON::PP::false does NOT pass Bool");
	is($exception, undef, "Bool coerced JSON::PP::true and JSON::PP::false");
	ok($values[0], "Bool coerced JSON::PP::true to true");
	ok(!$values[1], "Bool coerced JSON::PP::false to false");
}

done_testing;

