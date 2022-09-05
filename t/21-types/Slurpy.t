=pod

=encoding utf-8

=head1 PURPOSE

Basic tests for B<Slurpy> from L<Types::Standard>.

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
use Types::Standard qw( Slurpy );

isa_ok(Slurpy, 'Type::Tiny', 'Slurpy');
is(Slurpy->name, 'Slurpy', 'Slurpy has correct name');
is(Slurpy->display_name, 'Slurpy', 'Slurpy has correct display_name');
is(Slurpy->library, 'Types::Standard', 'Slurpy knows it is in the Types::Standard library');
ok(Types::Standard->has_type('Slurpy'), 'Types::Standard knows it has type Slurpy');
ok(!Slurpy->deprecated, 'Slurpy is not deprecated');
ok(!Slurpy->is_anon, 'Slurpy is not anonymous');
ok(Slurpy->can_be_inlined, 'Slurpy can be inlined');
is(exception { Slurpy->inline_check(q/$xyz/) }, undef, "Inlining Slurpy doesn't throw an exception");
ok(!Slurpy->has_coercion, "Slurpy doesn't have a coercion");
ok(Slurpy->is_parameterizable, "Slurpy is parameterizable");
isnt(Slurpy->type_default, undef, "Slurpy has a type_default");
is(Slurpy->type_default->(), undef, "Slurpy type_default is undef");

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
	pass => 'negative one'             => -1,
	pass => 'non integer'              =>  3.1416,
	pass => 'empty string'             => '',
	pass => 'whitespace'               => ' ',
	pass => 'line break'               => "\n",
	pass => 'random string'            => 'abc123',
	pass => 'loaded package name'      => 'Type::Tiny',
	pass => 'unloaded package name'    => 'This::Has::Probably::Not::Been::Loaded',
	pass => 'a reference to undef'     => do { my $x = undef; \$x },
	pass => 'a reference to false'     => do { my $x = !!0; \$x },
	pass => 'a reference to true'      => do { my $x = !!1; \$x },
	pass => 'a reference to zero'      => do { my $x = 0; \$x },
	pass => 'a reference to one'       => do { my $x = 1; \$x },
	pass => 'a reference to empty string' => do { my $x = ''; \$x },
	pass => 'a reference to random string' => do { my $x = 'abc123'; \$x },
	pass => 'blessed scalarref'        => bless(do { my $x = undef; \$x }, 'SomePkg'),
	pass => 'empty arrayref'           => [],
	pass => 'arrayref with one zero'   => [0],
	pass => 'arrayref of integers'     => [1..10],
	pass => 'arrayref of numbers'      => [1..10, 3.1416],
	pass => 'blessed arrayref'         => bless([], 'SomePkg'),
	pass => 'empty hashref'            => {},
	pass => 'hashref'                  => { foo => 1 },
	pass => 'blessed hashref'          => bless({}, 'SomePkg'),
	pass => 'coderef'                  => sub { 1 },
	pass => 'blessed coderef'          => bless(sub { 1 }, 'SomePkg'),
	pass => 'glob'                     => do { no warnings 'once'; *SOMETHING },
	pass => 'globref'                  => do { no warnings 'once'; my $x = *SOMETHING; \$x },
	pass => 'blessed globref'          => bless(do { no warnings 'once'; my $x = *SOMETHING; \$x }, 'SomePkg'),
	pass => 'regexp'                   => qr/./,
	pass => 'blessed regexp'           => bless(qr/./, 'SomePkg'),
	pass => 'filehandle'               => do { open my $x, '<', $0 or die; $x },
	pass => 'filehandle object'        => do { require IO::File; 'IO::File'->new($0, 'r') },
	pass => 'ref to scalarref'         => do { my $x = undef; my $y = \$x; \$y },
	pass => 'ref to arrayref'          => do { my $x = []; \$x },
	pass => 'ref to hashref'           => do { my $x = {}; \$x },
	pass => 'ref to coderef'           => do { my $x = sub { 1 }; \$x },
	pass => 'ref to blessed hashref'   => do { my $x = bless({}, 'SomePkg'); \$x },
	pass => 'object stringifying to ""' => do { package Local::OL::StringEmpty; use overload q[""] => sub { "" }; bless [] },
	pass => 'object stringifying to "1"' => do { package Local::OL::StringOne; use overload q[""] => sub { "1" }; bless [] },
	pass => 'object numifying to 0'    => do { package Local::OL::NumZero; use overload q[0+] => sub { 0 }; bless [] },
	pass => 'object numifying to 1'    => do { package Local::OL::NumOne; use overload q[0+] => sub { 1 }; bless [] },
	pass => 'object overloading arrayref' => do { package Local::OL::Array; use overload q[@{}] => sub { $_[0]{array} }; bless {array=>[]} },
	pass => 'object overloading hashref' => do { package Local::OL::Hash; use overload q[%{}] => sub { $_[0][0] }; bless [{}] },
	pass => 'object overloading coderef' => do { package Local::OL::Code; use overload q[&{}] => sub { $_[0][0] }; bless [sub { 1 }] },
#TESTS
);

while (@tests) {
	my ($expect, $label, $value) = splice(@tests, 0 , 3);
	if ($expect eq 'xxxx') {
		note("UNDEFINED OUTCOME: $label");
	}
	elsif ($expect eq 'pass') {
		should_pass($value, Slurpy, ucfirst("$label should pass Slurpy"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, Slurpy, ucfirst("$label should fail Slurpy"));
	}
	else {
		fail("expected '$expect'?!");
	}
}

# Should just pass through to the CodeRef check.
#

my $SlurpyCodeRef = Slurpy[ Types::Standard::CodeRef ];

my @tests_from_CodeRef = (
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
	fail => 'empty hashref'            => {},
	fail => 'hashref'                  => { foo => 1 },
	fail => 'blessed hashref'          => bless({}, 'SomePkg'),
	pass => 'coderef'                  => sub { 1 },
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
);

while (@tests_from_CodeRef) {
	my ($expect, $label, $value) = splice(@tests_from_CodeRef, 0 , 3);
	if ($expect eq 'xxxx') {
		note("UNDEFINED OUTCOME: $label");
	}
	elsif ($expect eq 'pass') {
		should_pass($value, $SlurpyCodeRef, ucfirst("$label should pass $SlurpyCodeRef"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, $SlurpyCodeRef, ucfirst("$label should fail $SlurpyCodeRef"));
	}
	else {
		fail("expected '$expect'?!");
	}
}

isnt(Slurpy->of( Types::Standard::HashRef )->type_default, undef, "Slurpy[HashRef] has a type_default");
is_deeply(Slurpy->of( Types::Standard::HashRef )->type_default->(), {}, "Slurpy[HashRef] type_default is {}");

is(Slurpy->of( Types::Standard::Defined )->type_default, undef, "Slurpy[Defined] has no type_default");

# Convenience method:
#
is( Slurpy->of( Types::Standard::Any )->my_slurp_into, 'ARRAY' );
is( Slurpy->of( Types::Standard::HashRef )->my_slurp_into, 'HASH' );
is( Slurpy->of( Types::Standard::Dict )->my_slurp_into, 'HASH' );
is( Slurpy->of( Types::Standard::Map )->my_slurp_into, 'HASH' );
is( Slurpy->of( Types::Standard::ArrayRef )->my_slurp_into, 'ARRAY' );
is( Slurpy->of( Types::Standard::Tuple )->my_slurp_into, 'ARRAY' );
is( Slurpy->of( Types::Standard::CycleTuple )->my_slurp_into, 'ARRAY' );

#
# See also: Dict.t, Tuple.t, CycleTuple.t.
#

done_testing;
