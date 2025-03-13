=pod

=encoding utf-8

=head1 PURPOSE

Basic tests for B<HashLike> from L<Types::TypeTiny>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019-2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::TypeTiny;
use Test::Requires qw(boolean);
use Types::TypeTiny qw( HashLike );

isa_ok(HashLike, 'Type::Tiny', 'HashLike');
is(HashLike->name, 'HashLike', 'HashLike has correct name');
is(HashLike->display_name, 'HashLike', 'HashLike has correct display_name');
is(HashLike->library, 'Types::TypeTiny', 'HashLike knows it is in the Types::TypeTiny library');
ok(Types::TypeTiny->has_type('HashLike'), 'Types::TypeTiny knows it has type HashLike');
ok(!HashLike->deprecated, 'HashLike is not deprecated');
ok(!HashLike->is_anon, 'HashLike is not anonymous');
ok(HashLike->can_be_inlined, 'HashLike can be inlined');
is(exception { HashLike->inline_check(q/$xyz/) }, undef, "Inlining HashLike doesn't throw an exception");
ok(!HashLike->has_coercion, "HashLike doesn't have a coercion");
ok(HashLike->is_parameterizable, "HashLike is parameterizable");
isnt(HashLike->type_default, undef, "HashLike has a type_default");
is_deeply(HashLike->type_default->(), {}, "HashLike type_default is {}");

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
	fail => 'blessed scalarref'        => bless(do { my $x = undef; \$x }, 'SomePkg'),
	fail => 'empty arrayref'           => [],
	fail => 'arrayref with one zero'   => [0],
	fail => 'arrayref of integers'     => [1..10],
	fail => 'arrayref of numbers'      => [1..10, 3.1416],
	fail => 'blessed arrayref'         => bless([], 'SomePkg'),
	pass => 'empty hashref'            => {},
	pass => 'hashref'                  => { foo => 1 },
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
	pass => 'object overloading hashref' => do { package Local::OL::Hash; use overload q[%{}] => sub { $_[0][0] }; bless [{}] },
	fail => 'object overloading coderef' => do { package Local::OL::Code; use overload q[&{}] => sub { $_[0][0] }; bless [sub { 1 }] },
	fail => 'object booling to false'  => do { package Local::OL::BoolFalse; use overload q[bool] => sub { 0 }; bless [] },
	fail => 'object booling to true'   => do { package Local::OL::BoolTrue;  use overload q[bool] => sub { 1 }; bless [] },
	fail => 'boolean::false'           => boolean::false,
	fail => 'boolean::true'            => boolean::true,
	fail => 'builtin::false'           => do { no warnings; builtin->can('false') ? builtin::false() : !!0 },
	fail => 'builtin::true'            => do { no warnings; builtin->can('true') ? builtin::true() : !!1 },
#TESTS
);

while (@tests) {
	my ($expect, $label, $value) = splice(@tests, 0 , 3);
	if ($expect eq 'xxxx') {
		note("UNDEFINED OUTCOME: $label");
	}
	elsif ($expect eq 'pass') {
		should_pass($value, HashLike, ucfirst("$label should pass HashLike"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, HashLike, ucfirst("$label should fail HashLike"));
	}
	else {
		fail("expected '$expect'?!");
	}
}

#
# Parameterizable
#

use Types::Standard ();

my $HashOfInt = HashLike[ Types::Standard::Int() ];

ok( $HashOfInt->can_be_inlined );

should_pass(
	{ foo => 1, bar => 2 },
	$HashOfInt,
);

should_pass(
	bless([{ foo => 1, bar => 2 }], 'Local::OL::Hash'),
	$HashOfInt,
);

should_fail(
	{ foo => 1, bar => undef },
	$HashOfInt,
);

should_fail(
	bless([{ foo => 1, bar => undef }], 'Local::OL::Hash'),
	$HashOfInt,
);

my $HashOfRounded = HashLike[
	Types::Standard::Int()->plus_coercions(
		Types::Standard::Num(), => q{ int($_) },
	)
];

is_deeply(
	$HashOfRounded->coerce({ foo => 1, bar => 2.1 }),
	{ foo => 1, bar => 2 },
);

# Note that because of coercion, the object overloading %{}
# is now a plain old hashref.
is_deeply(
	$HashOfRounded->coerce(bless([{ foo => 1, bar => 2.1 }], 'Local::OL::Hash')),
	{ foo => 1, bar => 2 },
);

is_deeply(
	$HashOfRounded->coerce({ foo => undef, bar => 2.1 }),
	{ foo => undef, bar => 2.1 },  # cannot be coerced, so returned unchanged
);

# can't use is_deeply because object doesn't overload eq
# but the idea is because the coercion fails, the original
# object gets returned unchanged
ok(
	Scalar::Util::blessed( $HashOfRounded->coerce(bless([{ foo => undef, bar => 2.1 }], 'Local::OL::Hash')) ),
);

#
# Tied hashes, and combining them with hash-overloaded objects
#

{
	package MaiTai::Hash;
	use Tie::Hash;
	our @ISA = 'Tie::Hash';
	sub TIEHASH   { bless [ {} ], $_[0]; }
	sub FETCH     { $_[0][0]{$_[1]}; }
	sub STORE     { $_[0][0]{$_[1]} = $_[2]; }
	sub FIRSTKEY  { my $a = scalar keys %{$_[0][0]}; each %{$_[0][0]} }
	sub NEXTKEY   { each %{$_[0][0]} }
	sub EXISTS    { exists $_[0][0]{$_[1]}; }
	sub DELETE    { delete $_[0][0]{$_[1]}; }
	sub CLEAR     { %{$_[0][0]} = () }
	sub SCALAR    { scalar %{$_[0][0]} }
	##
	package MaiObj::Hash;
	use overload '%{}' => sub {
		my $obj = shift;
		my %h;
		tie( %h, 'MaiTai::Hash' ) if $obj->[0];
		my @keys   = @{ $obj->[1] };
		my @values = @{ $obj->[2] };
		@h{ @keys } = @values;
		return \%h;
	};
	sub new {
		my ( $class, $do_tie ) = ( shift, shift );
		my ( @keys, @values );
		while ( @_ ) {
			push @keys, shift;
			push @values, shift;
		}
		bless [ $do_tie, \@keys, \@values ], $class;
	}
}

{
	my %h;
	tie( %h, 'MaiTai::Hash' );
	$h{foo} = 12;
	$h{bar} = 34;
	should_pass( \%h, $HashOfInt, 'tied hash that should pass' );
}

{
	my %h;
	tie( %h, 'MaiTai::Hash' );
	$h{foo} = 12;
	$h{bar} = 'xxx';
	should_fail( \%h, $HashOfInt, 'tied hash that should fail' );
}

{
	my $obj = 'MaiObj::Hash'->new( !!0, foo => 12, bar => 34 );
	should_pass( $obj, $HashOfInt, 'overloaded object yielding regular hash that should pass' );
}

{
	my $obj = 'MaiObj::Hash'->new( !!0, foo => 12, bar => 'xyz' );
	should_fail( $obj, $HashOfInt, 'overloaded object yielding regular hash that should fail' );
}

{
	my $obj = 'MaiObj::Hash'->new( !!1, foo => 12, bar => 34 );
	should_pass( $obj, $HashOfInt, 'overloaded object yielding tied hash that should pass' );
}

{
	my $obj = 'MaiObj::Hash'->new( !!1, foo => 12, bar => 'xyz' );
	should_fail( $obj, $HashOfInt, 'overloaded object yielding tied hash that should fail' );
}

done_testing;
