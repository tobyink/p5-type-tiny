=pod

=encoding utf-8

=head1 PURPOSE

Basic tests for B<ClassName> from L<Types::Standard>.

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
use Types::Standard qw( ClassName );

isa_ok(ClassName, 'Type::Tiny', 'ClassName');
is(ClassName->name, 'ClassName', 'ClassName has correct name');
is(ClassName->display_name, 'ClassName', 'ClassName has correct display_name');
is(ClassName->library, 'Types::Standard', 'ClassName knows it is in the Types::Standard library');
ok(Types::Standard->has_type('ClassName'), 'Types::Standard knows it has type ClassName');
ok(!ClassName->deprecated, 'ClassName is not deprecated');
ok(!ClassName->is_anon, 'ClassName is not anonymous');
ok(ClassName->can_be_inlined, 'ClassName can be inlined');
is(exception { ClassName->inline_check(q/$xyz/) }, undef, "Inlining ClassName doesn't throw an exception");
ok(!ClassName->has_coercion, "ClassName doesn't have a coercion");
ok(!ClassName->is_parameterizable, "ClassName isn't parameterizable");
is(ClassName->type_default, undef, "ClassName has no type_default");

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
	pass => 'loaded package name'      => 'Type::Tiny',
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
		should_pass($value, ClassName, ucfirst("$label should pass ClassName"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, ClassName, ucfirst("$label should fail ClassName"));
	}
	else {
		fail("expected '$expect'?!");
	}
}

#
# ClassName accepts Class::Tiny, Moo, Moose, and Mouse classes
#

if (eval q{ package Local::Class::ClassTiny; use Class::Tiny; 1 }) {
	should_pass('Local::Class::ClassTiny', ClassName);
}

if (eval q{ package Local::Class::Moo; use Moo; 1 }) {
	should_pass('Local::Class::Moo', ClassName);
}

if (eval q{ package Local::Class::Moose; use Moose; 1 }) {
	should_pass('Local::Class::Moose', ClassName);
}

if (eval q{ package Local::Class::Mouse; use Mouse; 1 }) {
	should_pass('Local::Class::Mouse', ClassName);
}

#
# ClassName accepts Role::Tiny, Moo::Role, Moose::Role, and Mouse::Role roles.
#
# This is because there's no way of knowing that these roles cannot be
# used as a class. Even if there's no method called `new`, there might
# be a constructor with a different name.
#

if (eval q{ package Local::Role::RoleTiny; use Role::Tiny; 1 }) {
	should_pass('Local::Role::RoleTiny', ClassName);
}

if (eval q{ package Local::Role::MooRole; use Moo::Role; 1 }) {
	should_pass('Local::Role::MooRole', ClassName);
}

if (eval q{ package Local::Role::MooseRole; use Moose::Role; 1 }) {
	should_pass('Local::Role::MooseRole', ClassName);
}

if (eval q{ package Local::Role::MouseRole; use Mouse::Role; 1 }) {
	should_pass('Local::Role::MouseRole', ClassName);
}

#
# ClassName accepts any package with $VERSION defined.
#

if (eval q{ package Local::Random::Package::One; our $VERSION = 1; 1 }) {
	should_pass('Local::Random::Package::One', ClassName);
}

#
# ClassName accepts any package with @ISA.
#

if (eval q{ package Local::Random::Package::Two; our @ISA = qw(Local::Random::Package::One); 1 }) {
	should_pass('Local::Random::Package::Two', ClassName);
}

if (eval q{ package Local::Random::Package::Three; our @ISA; 1 }) {
	# ... but an empty @ISA doesn't count.
	should_fail('Local::Random::Package::Three', ClassName);
}

done_testing;

