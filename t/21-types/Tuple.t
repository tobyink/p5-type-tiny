=pod

=encoding utf-8

=head1 PURPOSE

Basic tests for B<Tuple> from L<Types::Standard>.

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
use Types::Standard qw( Tuple );

isa_ok(Tuple, 'Type::Tiny', 'Tuple');
is(Tuple->name, 'Tuple', 'Tuple has correct name');
is(Tuple->display_name, 'Tuple', 'Tuple has correct display_name');
is(Tuple->library, 'Types::Standard', 'Tuple knows it is in the Types::Standard library');
ok(Types::Standard->has_type('Tuple'), 'Types::Standard knows it has type Tuple');
ok(!Tuple->deprecated, 'Tuple is not deprecated');
ok(!Tuple->is_anon, 'Tuple is not anonymous');
ok(Tuple->can_be_inlined, 'Tuple can be inlined');
is(exception { Tuple->inline_check(q/$xyz/) }, undef, "Inlining Tuple doesn't throw an exception");
ok(!Tuple->has_coercion, "Tuple doesn't have a coercion");
ok(Tuple->is_parameterizable, "Tuple is parameterizable");
isnt(Tuple->type_default, undef, "Tuple has a type_default");
is_deeply(Tuple->type_default->(), [], "Tuple type_default is []");

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
	pass => 'empty arrayref'           => [],
	pass => 'arrayref with one zero'   => [0],
	pass => 'arrayref of integers'     => [1..10],
	pass => 'arrayref of numbers'      => [1..10, 3.1416],
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
		should_pass($value, Tuple, ucfirst("$label should pass Tuple"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, Tuple, ucfirst("$label should fail Tuple"));
	}
	else {
		fail("expected '$expect'?!");
	}
}


#
# A basic tuple.
#

my $type1 = Tuple[
	Types::Standard::Int,
	Types::Standard::ArrayRef,
	Types::Standard::Undef,
];

should_pass( [42,[1..4],undef], $type1 );
should_fail( [{},[1..4],undef], $type1 ); # first slot fails
should_fail( [42,{    },undef], $type1 ); # second slot fails
should_fail( [42,[1..4],{  } ], $type1 ); # third slot fails
should_fail( [42,[1..4],undef,1], $type1 );  # too many slots
should_fail( [42,[1..4]], $type1 );  # not enough slots
should_fail( [], $type1 );  # not enough slots (empty arrayref)
should_fail( 42, $type1 );  # not even an arrayref
should_fail( bless([42,[1..10],undef], 'Foo'), $type1 ); # blessed

is($type1->type_default, undef, "$type1 has no type_default");

#
# Some Optional slots.
#

use Types::Standard qw( Optional );

my $type2 = Tuple[
	Types::Standard::Int,
	Types::Standard::ArrayRef,
	Optional[ Types::Standard::HashRef ],
	Optional[ Types::Standard::ScalarRef ],
];

should_pass([42,[],{},\0], $type2);
should_pass([42,[],{}], $type2);  # missing optional fourth slot
should_pass([42,[]], $type2);  # missing optional third slot
should_fail([42], $type2);  # missing required second slot
should_fail([], $type2); # missing required first slot
# can't put undef in slot 3 as a way to supply a value for slot 4
should_fail([42,[],undef,\0], $type2);


#
# The difference between Optional and Maybe
#

use Types::Standard qw( Maybe );

my $type3 = Tuple[
	Types::Standard::Int,
	Types::Standard::ArrayRef,
	Maybe[ Types::Standard::HashRef ],
	Maybe[ Types::Standard::ScalarRef ],
];

should_fail([42,[],{}], $type3);         # missing fourth slot fails!
should_pass([42,[],{},undef], $type3);   # ... but undef is okay


#
# Simple Slurpy example
#

use Types::Standard qw(Slurpy);

my $type4 = Tuple[
	Types::Standard::RegexpRef,
	Slurpy[ Types::Standard::ArrayRef[ Types::Standard::Int ] ],
];

should_pass([qr//], $type4);
should_pass([qr//,1..4], $type4);
should_fail([qr//,1..4,qr//], $type4);
# note that the Slurpy slurps stuff into an arrayref to check
# so it will fail when there's an actual arrayref there.
should_fail([qr//,[1..4]], $type4);


#
# Optional + Slurpy example
#

my $type5 = Tuple[
	Types::Standard::RegexpRef,
	Optional[ Types::Standard::HashRef ],
	Slurpy[ Types::Standard::ArrayRef[ Types::Standard::Int ] ],
];

should_pass([qr//], $type5);
should_pass([qr//,{}], $type5);
should_pass([qr//,{},1..4], $type5);
# can't omit Optional element but still provide slurpy
should_fail([qr//,1..4], $type5);


#
# Slurpy Tuple inside a Tuple
#

my $type6 = Tuple[
	Types::Standard::RegexpRef,
	Slurpy[ Types::Standard::Tuple[ Types::Standard::Int, Types::Standard::Int ] ],
];

should_pass([qr//], $type6);
should_fail([qr//,1], $type6);
should_pass([qr//,1,2], $type6); # pass because two ints
should_fail([qr//,1,2,3], $type6);
should_fail([qr//,1,2,3,4], $type6);
should_fail([qr//,1,2,3,4,5], $type6);


#
# Optional + Slurpy Tuple inside a Tuple
#

my $type7 = Tuple[
	Types::Standard::RegexpRef,
	Optional[ Types::Standard::RegexpRef ],
	Slurpy[ Types::Standard::Tuple[ Types::Standard::Int, Types::Standard::Int ] ],
];

should_pass([qr//], $type7);
should_pass([qr//,qr//], $type7);
should_fail([qr//,qr//,1], $type7);
should_pass([qr//,qr//,1,2], $type7); # pass because two ints after optional
should_fail([qr//,1,2], $type7);      # fail because two ints with no optional
should_fail([qr//,qr//,1,2,3], $type7);
should_fail([qr//,qr//,1,2,3,4], $type7);
should_fail([qr//,qr//,1,2,3,4,5], $type7);


#
# Simple Slurpy hashref example
#

my $type8 = Tuple[
	Types::Standard::RegexpRef,
	Slurpy[ Types::Standard::HashRef[ Types::Standard::Int ] ],
];

should_pass([qr//], $type8);
should_pass([qr//,foo=>1,bar=>2], $type8);
should_fail([qr//,foo=>1,bar=>2,qr//], $type8);
# note that the slurpy slurps stuff into an hashref to check
# so it will fail when there's an actual hashref there.
should_fail([qr//,{foo=>1,bar=>2}], $type8);
should_fail([qr//,'foo'], $type8);


#
# Optional + slurpy hashref example
#

my $type9 = Tuple[
	Types::Standard::RegexpRef,
	Optional[ Types::Standard::ScalarRef ],
	Slurpy[ Types::Standard::HashRef[ Types::Standard::Int ] ],
];

should_pass([qr//], $type9);
should_pass([qr//,\1], $type9);
should_pass([qr//,\1,foo=>1,bar=>2], $type9);
# can't omit Optional element but still provide Slurpy
should_fail([qr//,foo=>1,bar=>2], $type9);


#
# Deep coercions
#

my $Rounded = Types::Standard::Int->plus_coercions(
	Types::Standard::Num, sub{ int($_) },
);

my $type10 = Tuple[
	$Rounded,
	Types::Standard::ArrayRef[$Rounded],
	Optional[$Rounded],
	Slurpy[ Types::Standard::HashRef[$Rounded] ],
];

my $coerced = $type10->coerce([
	3.1,
	[ 1.1, 1.2, 1.3 ],
	4.2,
	foo => 5.1, bar => 6.1,
]);
subtest 'coercion happened as expected' => sub {
	is($coerced->[0], 3);
	is_deeply($coerced->[1], [1,1,1]);
	is($coerced->[2], 4);
	is_deeply({@$coerced[3..6]}, {foo=>5,bar=>6});
};

# One thing to note is that coercions succeed as a whole or fail as a whole.
# The tuple had to coerce the first element to an integer, the second to an
# arrayref of integers, the third (if it existed) to an integer, and whatever
# was left, it slurped into a temp hashef, coerced that to a hashref of
# integers, and then flattened that back into the tuple it was returning.
# If any single part of it had ended up not conforming to the target type,
# then the original tuple would have been returned with no coercions done
# at all!

#
# slurpy starting at an index greater or equal to 2
#
my $type11 = Tuple[
	Types::Standard::Int,
	Types::Standard::ScalarRef,
	Slurpy[ Types::Standard::HashRef ],
];
should_pass([1,\1], $type11);
should_pass([1,\1,foo=>3], $type11);
should_fail([1,\1,'foo'], $type11);


#
# Coercion with CHILD OF slurpy
#

my $type12 = Tuple[
	$Rounded,
	Types::Standard::ArrayRef[$Rounded],
	Optional[$Rounded],
	( Slurpy[ Types::Standard::HashRef[$Rounded] ] )->create_child_type( coercion => 1 ),
];

my $coerced2 = $type12->coerce([
	3.1,
	[ 1.1, 1.2, 1.3 ],
	4.2,
	foo => 5.1, bar => 6.1,
]);
subtest 'coercion happened as expected' => sub {
	is($coerced2->[0], 3);
	is_deeply($coerced2->[1], [1,1,1]);
	is($coerced2->[2], 4);
	is_deeply({@$coerced2[3..6]}, {foo=>5,bar=>6});
};

done_testing;

