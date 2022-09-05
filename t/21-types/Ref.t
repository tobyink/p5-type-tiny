=pod

=encoding utf-8

=head1 PURPOSE

Basic tests for B<Ref> from L<Types::Standard>.

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
use Types::Standard qw( Ref );

isa_ok(Ref, 'Type::Tiny', 'Ref');
is(Ref->name, 'Ref', 'Ref has correct name');
is(Ref->display_name, 'Ref', 'Ref has correct display_name');
is(Ref->library, 'Types::Standard', 'Ref knows it is in the Types::Standard library');
ok(Types::Standard->has_type('Ref'), 'Types::Standard knows it has type Ref');
ok(!Ref->deprecated, 'Ref is not deprecated');
ok(!Ref->is_anon, 'Ref is not anonymous');
ok(Ref->can_be_inlined, 'Ref can be inlined');
is(exception { Ref->inline_check(q/$xyz/) }, undef, "Inlining Ref doesn't throw an exception");
ok(!Ref->has_coercion, "Ref doesn't have a coercion");
ok(Ref->is_parameterizable, "Ref is parameterizable");
is(Ref->type_default, undef, "Ref has no type_default");

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
	fail => 'glob'                     => do { no warnings 'once'; *SOMETHING },
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
		should_pass($value, Ref, ucfirst("$label should pass Ref"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, Ref, ucfirst("$label should fail Ref"));
	}
	else {
		fail("expected '$expect'?!");
	}
}

#
# Tests for parameterized Ref
# Ref['HASH']
# Ref['ARRAY']
# Ref['SCALAR']
# Ref['CODE']
# Ref['GLOB']
# Ref['LVALUE']
#

my $x = 1;
my %more_tests = (
	HASH      => [ {}, bless({}, 'Foo') ],
	ARRAY     => [ [], bless([], 'Foo') ],
	SCALAR    => [ do { my $x; \$x }, bless(do { my $x; \$x }, 'Foo') ],
	CODE      => [ sub { 1 }, bless(sub { 1 }, 'Foo') ],
	GLOB      => do { no warnings;[ \*BLEH, bless(\*BLEH2, 'Foo') ] },
#	LVALUE    => [ \substr($x, 0, 1), bless(\substr($x, 0, 1), 'Foo') ],
);
my @reftypes = sort keys %more_tests;

# The LVALUE examples *do* work, but generating output for the test
# via Data::Dumper results in annoying warning messages, so the tests
# are disabled.

# Regexp, IO, FORMAT, VSTRING are all "todo".

for my $reftype (@reftypes) {
	my $type = Ref[$reftype];
	
	note("== $type ==");
	
	isa_ok($type, 'Type::Tiny', '$type');
	ok($type->is_anon, '$type is not anonymous');
	ok($type->can_be_inlined, '$type can be inlined');
	is(exception { $type->inline_check(q/$xyz/) }, undef, "Inlining \$type doesn't throw an exception");
	ok(!$type->has_coercion, "\$type doesn't have a coercion");
	ok(!$type->is_parameterizable, "\$type isn't parameterizable");
	ok($type->is_parameterized, "\$type is parameterized");
	is($type->parameterized_from, Ref, "\$type's parent is Ref");
	
	foreach my $other (@reftypes) {
		my @values = @{ $more_tests{$other} };
		if ($reftype eq $other) {
			should_pass($_, $type) for @values;
		}
		else {
			should_fail($_, $type) for @values;
		}
	}
}

done_testing;

