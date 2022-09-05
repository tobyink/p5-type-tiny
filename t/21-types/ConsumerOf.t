=pod

=encoding utf-8

=head1 PURPOSE

Basic tests for B<ConsumerOf> from L<Types::Standard>.

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
use Types::Standard qw( ConsumerOf );

isa_ok(ConsumerOf, 'Type::Tiny', 'ConsumerOf');
is(ConsumerOf->name, 'ConsumerOf', 'ConsumerOf has correct name');
is(ConsumerOf->display_name, 'ConsumerOf', 'ConsumerOf has correct display_name');
is(ConsumerOf->library, 'Types::Standard', 'ConsumerOf knows it is in the Types::Standard library');
ok(Types::Standard->has_type('ConsumerOf'), 'Types::Standard knows it has type ConsumerOf');
ok(!ConsumerOf->deprecated, 'ConsumerOf is not deprecated');
ok(!ConsumerOf->is_anon, 'ConsumerOf is not anonymous');
ok(ConsumerOf->can_be_inlined, 'ConsumerOf can be inlined');
is(exception { ConsumerOf->inline_check(q/$xyz/) }, undef, "Inlining ConsumerOf doesn't throw an exception");
ok(!ConsumerOf->has_coercion, "ConsumerOf doesn't have a coercion");
ok(ConsumerOf->is_parameterizable, "ConsumerOf is parameterizable");
is(ConsumerOf->type_default, undef, "ConsumerOf has no type_default");

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
		should_pass($value, ConsumerOf, ucfirst("$label should pass ConsumerOf"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, ConsumerOf, ucfirst("$label should fail ConsumerOf"));
	}
	else {
		fail("expected '$expect'?!");
	}
}

#
# Parameterized ConsumerOf returns a Type::Tiny::Role.
#

should_pass(ConsumerOf['Foo'], ConsumerOf['Type::Tiny::Role']);
should_pass(ConsumerOf['Foo'], ConsumerOf['Type::Tiny']);

#
# If Foo::Bar is a subclass of Foo, then Foo::Bar objects
# should pass ConsumerOf['Foo'] but not the other way around.
# (Note: UNIVERSAL::DOES calls $object->isa.)
#

@Foo::Bar::ISA = qw( Foo );
should_pass( bless([], 'Foo::Bar'),  ConsumerOf['Foo::Bar'] );
should_pass( bless([], 'Foo::Bar'),  ConsumerOf['Foo']      );
should_fail( bless([], 'Foo'),       ConsumerOf['Foo::Bar'] );
should_pass( bless([], 'Foo'),       ConsumerOf['Foo']      );

#
# Parameterized ConsumerOf with two parameters returns a
# Type::Tiny::Intersection of two Type::Tiny::Role objects.
#

my $fb = ConsumerOf['Foo','Bar'];
should_pass($fb, ConsumerOf['Type::Tiny::Intersection']);
should_pass($fb, ConsumerOf['Type::Tiny']);
is(scalar(@$fb), 2);
should_pass($fb->[0], ConsumerOf['Type::Tiny::Role']);
should_pass($fb->[1], ConsumerOf['Type::Tiny::Role']);

{ package Foo; package Bar; }
@MyConsumer::ISA = qw( Foo Bar );
should_pass( bless([], 'MyConsumer'), $fb );

#
# Test using Class::Tiny and Role::Tiny
#

if (eval q{
	package My::TinyRole;
	use Role::Tiny;
	package My::TinyClass;
	use Class::Tiny;
	use Role::Tiny::With;
	with 'My::TinyRole';
	1 }) {
	should_pass(My::TinyClass->new, ConsumerOf['My::TinyRole']);
	should_pass(My::TinyClass->new, ConsumerOf['My::TinyClass']);
}

#
# Test using Moo
#

if (eval q{
	package My::MooRole;
	use Moo::Role;
	package My::MooClass;
	use Moo;
	with 'My::MooRole';
	1 }) {
	should_pass(My::MooClass->new, ConsumerOf['My::MooRole']);
	should_pass(My::MooClass->new, ConsumerOf['My::MooClass']);
}

#
# Test using Moose
#

if (eval q{
	package My::MooseRole;
	use Moose::Role;
	package My::MooseClass;
	use Moose;
	with 'My::MooseRole';
	1 }) {
	should_pass(My::MooseClass->new, ConsumerOf['My::MooseRole']);
	should_pass(My::MooseClass->new, ConsumerOf['My::MooseClass']);
}

#
# Test using Mouse
#

if (eval q{
	package My::MouseRole;
	use Mouse::Role;
	package My::MouseClass;
	use Mouse;
	with 'My::MouseRole';
	1 }) {
	should_pass(My::MouseClass->new, ConsumerOf['My::MouseRole']);
	should_pass(My::MouseClass->new, ConsumerOf['My::MouseClass']);
}

done_testing;

