=pod

=encoding utf-8

=head1 PURPOSE

Basic tests for B<Optional> from L<Types::Standard>.

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
use Types::Standard qw( Optional );

isa_ok(Optional, 'Type::Tiny', 'Optional');
is(Optional->name, 'Optional', 'Optional has correct name');
is(Optional->display_name, 'Optional', 'Optional has correct display_name');
is(Optional->library, 'Types::Standard', 'Optional knows it is in the Types::Standard library');
ok(Types::Standard->has_type('Optional'), 'Types::Standard knows it has type Optional');
ok(!Optional->deprecated, 'Optional is not deprecated');
ok(!Optional->is_anon, 'Optional is not anonymous');
ok(Optional->can_be_inlined, 'Optional can be inlined');
is(exception { Optional->inline_check(q/$xyz/) }, undef, "Inlining Optional doesn't throw an exception");
ok(!Optional->has_coercion, "Optional doesn't have a coercion");
ok(Optional->is_parameterizable, "Optional is parameterizable");
isnt(Optional->type_default, undef, "Optional has a type_default");
is(Optional->type_default->(), undef, "Optional type_default is undef");

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
		should_pass($value, Optional, ucfirst("$label should pass Optional"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, Optional, ucfirst("$label should fail Optional"));
	}
	else {
		fail("expected '$expect'?!");
	}
}

#
# Optional[X] is basically just the same as X. Optional acts like a no-op.
# Optional is just a hint to Dict/Tuple/CycleTuple and Type::Params.
#

my $type = Optional[ Types::Standard::Int ];
should_pass(0, $type);
should_pass(1, $type);
should_fail(1.1, $type);
should_fail(undef, $type);

isnt($type->type_default, undef, "$type has a type_default");
is($type->type_default->(), 0, "$type type_default is zero, because of Int's type_default");

if (eval q{
	package Local::MyClass::Moo;
	use Moo;
	use Types::Standard qw( Int Optional );
	has xyz => ( is => 'ro', isa => Optional[Int] );
	1;
}) {
	my $e;
	
	$e = exception {
		Local::MyClass::Moo->new( xyz => 0 );
	};
	is($e, undef);
	
	$e = exception {
		Local::MyClass::Moo->new( xyz => 1 );
	};
	is($e, undef);
	
	$e = exception {
		Local::MyClass::Moo->new( xyz => 1.1 );
	};
	like($e, qr/type constraint/);
	
	$e = exception {
		Local::MyClass::Moo->new( xyz => undef );
	};
	like($e, qr/type constraint/);
}

if (eval q{
	package Local::MyClass::Moose;
	use Moose;
	use Types::Standard qw( Int Optional );
	has xyz => ( is => 'ro', isa => Optional[Int] );
	1;
}) {
	my $e;
	
	$e = exception {
		Local::MyClass::Moose->new( xyz => 0 );
	};
	is($e, undef);
	
	$e = exception {
		Local::MyClass::Moose->new( xyz => 1 );
	};
	is($e, undef);
	
	$e = exception {
		Local::MyClass::Moose->new( xyz => 1.1 );
	};
	like($e, qr/type constraint/);
	
	$e = exception {
		Local::MyClass::Moose->new( xyz => undef );
	};
	like($e, qr/type constraint/);
}

if (eval q{
	package Local::MyClass::Mouse;
	use Mouse;
	use Types::Standard qw( Int Optional );
	has xyz => ( is => 'ro', isa => Optional[Int] );
	1;
}) {
	my $e;
	
	$e = exception {
		Local::MyClass::Mouse->new( xyz => 0 );
	};
	is($e, undef);
	
	$e = exception {
		Local::MyClass::Mouse->new( xyz => 1 );
	};
	is($e, undef);
	
	$e = exception {
		Local::MyClass::Mouse->new( xyz => 1.1 );
	};
	like($e, qr/type constraint/);
	
	$e = exception {
		Local::MyClass::Mouse->new( xyz => undef );
	};
	like($e, qr/type constraint/);
}

#
# See also: Dict.t, Tuple.t, CycleTuple.t.
#

done_testing;

