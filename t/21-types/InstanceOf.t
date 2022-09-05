=pod

=encoding utf-8

=head1 PURPOSE

Basic tests for B<InstanceOf> from L<Types::Standard>.

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
use Types::Standard qw( InstanceOf );

isa_ok(InstanceOf, 'Type::Tiny', 'InstanceOf');
is(InstanceOf->name, 'InstanceOf', 'InstanceOf has correct name');
is(InstanceOf->display_name, 'InstanceOf', 'InstanceOf has correct display_name');
is(InstanceOf->library, 'Types::Standard', 'InstanceOf knows it is in the Types::Standard library');
ok(Types::Standard->has_type('InstanceOf'), 'Types::Standard knows it has type InstanceOf');
ok(!InstanceOf->deprecated, 'InstanceOf is not deprecated');
ok(!InstanceOf->is_anon, 'InstanceOf is not anonymous');
ok(InstanceOf->can_be_inlined, 'InstanceOf can be inlined');
is(exception { InstanceOf->inline_check(q/$xyz/) }, undef, "Inlining InstanceOf doesn't throw an exception");
ok(!InstanceOf->has_coercion, "InstanceOf doesn't have a coercion");
ok(InstanceOf->is_parameterizable, "InstanceOf is parameterizable");
is(InstanceOf->type_default, undef, "InstanceOf has no type_default");

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
		should_pass($value, InstanceOf, ucfirst("$label should pass InstanceOf"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, InstanceOf, ucfirst("$label should fail InstanceOf"));
	}
	else {
		fail("expected '$expect'?!");
	}
}

#
# Parameterized InstanceOf returns a Type::Tiny::Class.
#

should_pass(InstanceOf['Foo'], InstanceOf['Type::Tiny::Class']);
should_pass(InstanceOf['Foo'], InstanceOf['Type::Tiny']);

#
# If Foo::Bar is a subclass of Foo, then Foo::Bar objects
# should pass InstanceOf['Foo'] but not the other way around.
#

@Foo::Bar::ISA = qw( Foo );
should_pass( bless([], 'Foo::Bar'),  InstanceOf['Foo::Bar'] );
should_pass( bless([], 'Foo::Bar'),  InstanceOf['Foo']      );
should_fail( bless([], 'Foo'),       InstanceOf['Foo::Bar'] );
should_pass( bless([], 'Foo'),       InstanceOf['Foo']      );

#
# Foo::Baz claims to be a Foo.
#

{
	package Foo::Baz;
	sub isa {
		return 1 if $_[1] eq 'Foo';
		shift->SUPER::isa(@_);
	}
}
should_pass( bless([], 'Foo::Baz'),  InstanceOf['Foo::Baz'] );
should_pass( bless([], 'Foo::Baz'),  InstanceOf['Foo']      );
should_fail( bless([], 'Foo'),       InstanceOf['Foo::Baz'] );
should_pass( bless([], 'Foo'),       InstanceOf['Foo']      );

#
# Parameterized InstanceOf with two parameters returns
# a Type::Tiny::Union of two Type::Tiny::Class objects.
#

my $fb = InstanceOf['Foo','Bar'];
should_pass($fb, InstanceOf['Type::Tiny::Union']);
should_pass($fb, InstanceOf['Type::Tiny']);
is(scalar(@$fb), 2);
should_pass($fb->[0], InstanceOf['Type::Tiny::Class']);
should_pass($fb->[1], InstanceOf['Type::Tiny::Class']);

should_pass( bless([], 'Foo'), $fb );
should_pass( bless([], 'Bar'), $fb );

#
# with_attribute_values
#

{
	package Local::Person;
	sub new {
		my $class = shift;
		my %args  = (@_==1) ? %{$_[0]} : @_;
		bless \%args, $class;
	}
	sub name   { shift->{name}   }
	sub gender { shift->{gender} }
}

my $Person = InstanceOf['Local::Person'];

ok( $Person->can('with_attribute_values') );

my $Man = $Person->with_attribute_values(
	gender => Types::Standard::Enum['m']
);

my $alice = 'Local::Person'->new( name => 'Alice', gender => 'f' );
my $bob   = 'Local::Person'->new( name => 'Bob',   gender => 'm' );

should_pass($alice, $Person);
should_pass($bob,   $Person);
should_fail($alice, $Man);
should_pass($bob,   $Man);

done_testing;

