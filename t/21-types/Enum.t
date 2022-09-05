=pod

=encoding utf-8

=head1 PURPOSE

Basic tests for B<Enum> from L<Types::Standard>.

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
use Types::Standard qw( Enum );

isa_ok(Enum, 'Type::Tiny', 'Enum');
is(Enum->name, 'Enum', 'Enum has correct name');
is(Enum->display_name, 'Enum', 'Enum has correct display_name');
is(Enum->library, 'Types::Standard', 'Enum knows it is in the Types::Standard library');
ok(Types::Standard->has_type('Enum'), 'Types::Standard knows it has type Enum');
ok(!Enum->deprecated, 'Enum is not deprecated');
ok(!Enum->is_anon, 'Enum is not anonymous');
ok(Enum->can_be_inlined, 'Enum can be inlined');
is(exception { Enum->inline_check(q/$xyz/) }, undef, "Inlining Enum doesn't throw an exception");
ok(!Enum->has_coercion, "Enum doesn't have a coercion");
ok(Enum->is_parameterizable, "Enum is parameterizable");
is(Enum->type_default, undef, "Enum has no type_default");

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
		should_pass($value, Enum, ucfirst("$label should pass Enum"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, Enum, ucfirst("$label should fail Enum"));
	}
	else {
		fail("expected '$expect'?!");
	}
}

#
# Parameterize with some strings.
#

my $enum1 = Enum[qw/ foo bar bar baz /];
should_pass('foo', $enum1);
should_pass('bar', $enum1);
should_pass('baz', $enum1);
should_fail('bat', $enum1);
is_deeply($enum1->values, [qw/ foo bar bar baz /]);
is_deeply($enum1->unique_values, [qw/ bar baz foo /]);
is_deeply([@$enum1], [qw/ foo bar bar baz /]);

#
# Regexp.
#

my $re = $enum1->as_regexp;
ok('foo' =~ $re);
ok('bar' =~ $re);
ok('baz' =~ $re);
ok('FOO' !~ $re);
ok('xyz' !~ $re);
ok('foo bar baz' !~ $re);

my $re_i = $enum1->as_regexp('i'); # case-insensitive
ok('foo' =~ $re_i);
ok('bar' =~ $re_i);
ok('baz' =~ $re_i);
ok('FOO' =~ $re_i);
ok('xyz' !~ $re_i);
ok('foo bar baz' !~ $re_i);

like(
	exception { $enum1->as_regexp('42') },
	qr/Unknown regexp flags/,
	'Unknown flags passed to as_regexp'
);

#
# Enum allows you to pass objects overloading stringification when
# creating the type, but rejects blessed objects (even overloaded)
# when checking values.
#

{
	package Local::Stringy;
	use overload q[""] => sub { ${$_[0]} };
	sub new { my ($class, $str) = @_; bless \$str, $class }
}

my $enum2 = Enum[
	map Local::Stringy->new($_), qw/ foo bar bar baz /
];
should_pass('foo', $enum2);
should_pass('bar', $enum2);
should_pass('baz', $enum2);
should_fail('bat', $enum2);
should_fail(Local::Stringy->new('foo'), $enum2);
is_deeply($enum2->values, [qw/ foo bar bar baz /]);
is_deeply($enum2->unique_values, [qw/ bar baz foo /]);
is_deeply([@$enum2], [qw/ foo bar bar baz /]);

#
# Enum-wise sorting
#

is_deeply(
	[ $enum1->sort( 'baz', 'foo' ) ],
	[ 'foo', 'baz' ],
	'"foo" comes before "baz" because they were listed in that order when $enum1 was defined',
);

#
# Auto coercion
#

my $enum3 = Enum[ \1, qw( FOO BAR BAZ ) ];
is $enum3->coerce('FOO'), 'FOO';
is $enum3->coerce('foo'), 'FOO';
is $enum3->coerce('f'),   'FOO';
is $enum3->coerce('ba'),  'BAR';
is $enum3->coerce('baz'), 'BAZ';
is $enum3->coerce(0),     'FOO';
is $enum3->coerce(1),     'BAR';
is $enum3->coerce(2),     'BAZ';
is $enum3->coerce(-1),    'BAZ';
is $enum3->coerce('XYZ'), 'XYZ';
is_deeply $enum3->coerce([123]), [123];

#
# Manual coercion
#

my $enum4 = Enum[
	[
		Types::Standard::ArrayRef() => sub { 'FOO' },
		Types::Standard::HashRef()  => sub { 'BAR' },
		Types::Standard::Str()      => sub { 'BAZ' },
	],
	qw( FOO BAR BAZ )
];

is $enum4->coerce([]), 'FOO';
is $enum4->coerce({}), 'BAR';
is $enum4->coerce(''), 'BAZ';

done_testing;

