=pod

=encoding utf-8

=head1 PURPOSE

Basic tests for B<HasMethods> from L<Types::Standard>.

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
use Types::Standard qw( HasMethods );

isa_ok(HasMethods, 'Type::Tiny', 'HasMethods');
is(HasMethods->name, 'HasMethods', 'HasMethods has correct name');
is(HasMethods->display_name, 'HasMethods', 'HasMethods has correct display_name');
is(HasMethods->library, 'Types::Standard', 'HasMethods knows it is in the Types::Standard library');
ok(Types::Standard->has_type('HasMethods'), 'Types::Standard knows it has type HasMethods');
ok(!HasMethods->deprecated, 'HasMethods is not deprecated');
ok(!HasMethods->is_anon, 'HasMethods is not anonymous');
ok(HasMethods->can_be_inlined, 'HasMethods can be inlined');
is(exception { HasMethods->inline_check(q/$xyz/) }, undef, "Inlining HasMethods doesn't throw an exception");
ok(!HasMethods->has_coercion, "HasMethods doesn't have a coercion");
ok(HasMethods->is_parameterizable, "HasMethods is parameterizable");
is(HasMethods->type_default, undef, "HasMethods has no type_default");

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
	fail => 'a reference to undef'     => do { my $x = undef; \$x },
	fail => 'a reference to false'     => do { my $x = !!0; \$x },
	fail => 'a reference to true'      => do { my $x = !!1; \$x },
	fail => 'a reference to zero'      => do { my $x = 0; \$x },
	fail => 'a reference to one'       => do { my $x = 1; \$x },
	fail => 'a reference to empty string' => do { my $x = ''; \$x },
	fail => 'a reference to random string' => do { my $x = 'abc123'; \$x },
	pass => 'blessed scalarref'        => bless(do { my $x = undef; \$x }, 'SomePkg'),
	fail => 'empty arrayref'           => [],
	fail => 'arrayref with one zero'   => [0],
	fail => 'arrayref of integers'     => [1..10],
	fail => 'arrayref of numbers'      => [1..10, 3.1416],
	pass => 'blessed arrayref'         => bless([], 'SomePkg'),
	fail => 'empty hashref'            => {},
	fail => 'hashref'                  => { foo => 1 },
	pass => 'blessed hashref'          => bless({}, 'SomePkg'),
	fail => 'coderef'                  => sub { 1 },
	pass => 'blessed coderef'          => bless(sub { 1 }, 'SomePkg'),
	fail => 'glob'                     => do { no warnings 'once'; *SOMETHING },
	fail => 'globref'                  => do { no warnings 'once'; my $x = *SOMETHING; \$x },
	pass => 'blessed globref'          => bless(do { no warnings 'once'; my $x = *SOMETHING; \$x }, 'SomePkg'),
	xxxx => 'regexp'                   => qr/./,
	pass => 'blessed regexp'           => bless(qr/./, 'SomePkg'),
	fail => 'filehandle'               => do { open my $x, '<', $0 or die; $x },
	pass => 'filehandle object'        => do { require IO::File; 'IO::File'->new($0, 'r') },
	fail => 'ref to scalarref'         => do { my $x = undef; my $y = \$x; \$y },
	fail => 'ref to arrayref'          => do { my $x = []; \$x },
	fail => 'ref to hashref'           => do { my $x = {}; \$x },
	fail => 'ref to coderef'           => do { my $x = sub { 1 }; \$x },
	fail => 'ref to blessed hashref'   => do { my $x = bless({}, 'SomePkg'); \$x },
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
		should_pass($value, HasMethods, ucfirst("$label should pass HasMethods"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, HasMethods, ucfirst("$label should fail HasMethods"));
	}
	else {
		fail("expected '$expect'?!");
	}
}

use Scalar::Util qw( refaddr );
my $plain  = HasMethods;
my $paramd = HasMethods[];
is(
	refaddr($plain),
	refaddr($paramd),
	'parameterizing with [] has no effect'
);

my $p1 = HasMethods['foo'];
my $p2 = HasMethods['foo'];
is(refaddr($p1), refaddr($p2), 'parameterizing is cached');


#
# We need a real object to test HasMethods on.
# Luckily HasMethods IS an object!
#

should_pass(
	HasMethods,
	HasMethods['constraint'],
	"Parameterized with one method name",
);

should_pass(
	HasMethods,
	HasMethods['constraint', 'name'],
	"Parameterized with multiple method names",
);

should_fail(
	HasMethods,
	HasMethods['constraint', 'should_not_exist'],
	"... acts as intersection (requires the object to support ALL the methods)"
);

{
	# A package where $thing->foo works but
	# $thing->can("foo") is false.
	package Local::Liar1;
	sub foo { 1 }
	sub can {
		return if $_[1] eq 'foo';
		goto \&UNIVERSAL::can;
	}
}

should_fail(
	bless([], 'Local::Liar1'),
	HasMethods['foo'],
	"HasMethods should believe \$object->can() if it returns false."
);

{
	# A package where $thing->foo breaks but
	# $thing->can("foo") is true.
	package Local::Liar2;
	sub can {
		return sub { 1 } if $_[1] eq 'foo';
		goto \&UNIVERSAL::can;
	}
}

should_pass(
	bless([], 'Local::Liar2'),
	HasMethods['foo'],
	"HasMethods should believe \$object->can() if it returns true."
);

#
# HasMethods is for blessed objects only.
#

should_fail(
	'Local::Liar2',
	HasMethods['foo'],
	"HasMethods does't work on class names, even if they can do a method."
);

done_testing;

