=pod

=encoding utf-8

=head1 PURPOSE

Basic tests for B<DelimitedStr> from L<Types::Common::String>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can rediDelimitedStribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::TypeTiny;
use Types::Common::String qw( DelimitedStr );

isa_ok(DelimitedStr, 'Type::Tiny', 'DelimitedStr');
is(DelimitedStr->name, 'DelimitedStr', 'DelimitedStr has correct name');
is(DelimitedStr->display_name, 'DelimitedStr', 'DelimitedStr has correct display_name');
is(DelimitedStr->library, 'Types::Common::String', 'DelimitedStr knows it is in the Types::Common::String library');
ok(Types::Common::String->has_type('DelimitedStr'), 'Types::Common::String knows it has type DelimitedStr');
ok(!DelimitedStr->deprecated, 'DelimitedStr is not deprecated');
ok(!DelimitedStr->is_anon, 'DelimitedStr is not anonymous');
ok(DelimitedStr->can_be_inlined, 'DelimitedStr can be inlined');
is(exception { DelimitedStr->inline_check(q/$xyz/) }, undef, "Inlining DelimitedStr doesn't throw an exception");
ok(DelimitedStr->has_coercion, "DelimitedStr has a coercion");
ok(DelimitedStr->is_parameterizable, "DelimitedStr is parameterizable");
is(DelimitedStr->type_default, undef, "DelimitedStr has a type_default");

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
	fail => 'object string to ""'      => do { package Local::OL::StringEmpty; use overload q[""] => sub { "" }; bless [] },
	fail => 'object string to "1"'     => do { package Local::OL::StringOne; use overload q[""] => sub { "1" }; bless [] },
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
		should_pass($value, DelimitedStr, ucfirst("$label should pass DelimitedStr"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, DelimitedStr, ucfirst("$label should fail DelimitedStr"));
	}
	else {
		fail("expected '$expect'?!");
	}
}

{
	local $" = '|';
	is(
		DelimitedStr->coerce( [ 1..4 ] ),
		'1|2|3|4',
		'The unparameterized type coerces by joining with $"',
	);
	
	$" = ',';
	is(
		DelimitedStr->coerce( [ 1..4 ] ),
		'1,2,3,4',
		'... and again',
	);

	$" = '';
	is(
		DelimitedStr->coerce( [ 1..4 ] ),
		'1234',
		'... and again',
	);
}

use Types::Standard qw( Int ArrayRef );

# Two or three integers, separated by commas, with optional whitespace
# around the commas.
#
my $SomeInts = DelimitedStr[ q{,}, Int, 2, 3, !!1 ];

ok( $SomeInts->can_be_inlined, '$SomeInts->can_be_inlined' );
ok( $SomeInts->coercion->can_be_inlined, '$SomeInts->coercion->can_be_inlined' );
is( $SomeInts->display_name, q{DelimitedStr[",",Int,2,3,1]}, '$SomeInts->display_name is ' . $SomeInts );

should_pass( '1,2,3', $SomeInts );
should_pass( '1, 2, 3', $SomeInts );
should_pass( '  1,2,3 ' . "\t\n\t", $SomeInts );
should_fail( '1', $SomeInts );
should_fail( '1,2,3,4', $SomeInts );
should_fail( 'foo,bar,baz', $SomeInts );
should_fail( '1,,3', $SomeInts );

ok(
	$SomeInts->coercion->has_coercion_for_type( ArrayRef[ Int, 2, 3 ] ),
	"$SomeInts has a coercion from an appropriate arrayref",
);

is(
	$SomeInts->coerce( [ 4, 5, 6 ] ),
	'4,5,6',
	'... and it works',
);

ok(
	!$SomeInts->coercion->has_coercion_for_type( ArrayRef[Int] ),
	"$SomeInts does not have a coercion from a posentially inappropriate arrayref",
);

done_testing;
