=pod

=encoding utf-8

=head1 PURPOSE

Basic tests for B<Dict> from L<Types::Standard>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::TypeTiny;
use Types::Standard qw( Dict );

isa_ok(Dict, 'Type::Tiny', 'Dict');
is(Dict->name, 'Dict', 'Dict has correct name');
is(Dict->display_name, 'Dict', 'Dict has correct display_name');
is(Dict->library, 'Types::Standard', 'Dict knows it is in the Types::Standard library');
ok(Types::Standard->has_type('Dict'), 'Types::Standard knows it has type Dict');
ok(!Dict->deprecated, 'Dict is not deprecated');
ok(!Dict->is_anon, 'Dict is not anonymous');
ok(Dict->can_be_inlined, 'Dict can be inlined');
is(exception { Dict->inline_check(q/$xyz/) }, undef, "Inlining Dict doesn't throw an exception");
ok(!Dict->has_coercion, "Dict doesn't have a coercion");
ok(Dict->is_parameterizable, "Dict is parameterizable");

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
		should_pass($value, Dict, ucfirst("$label should pass Dict"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, Dict, ucfirst("$label should fail Dict"));
	}
	else {
		fail("expected '$expect'?!");
	}
}

#
# Basic parameterized example
#

my $type1 = Dict[
	foo => Types::Standard::Int,
	bar => Types::Standard::RegexpRef,
];

should_pass( { foo => 42, bar => qr// }, $type1 );
should_fail( { foo => [], bar => qr// }, $type1 );
should_fail( { foo => 42, bar => 1234 }, $type1 );
should_fail( { foo => [], bar => 1234 }, $type1 );
should_fail( { foo => 42              }, $type1 );
should_fail( {            bar => qr// }, $type1 );
should_fail( [ foo => 42, bar => qr// ], $type1 );
should_fail( { foo => 42, bar => qr//, baz => undef }, $type1 );

ok(  $type1->my_hashref_allows_key('bar'),  'my_hashref_allows_key("bar")' );
ok( !$type1->my_hashref_allows_key('baz'), '!my_hashref_allows_key("baz")' );
ok(  $type1->my_hashref_allows_value('bar', qr//),  'my_hashref_allows_value("bar", qr//)' );
ok( !$type1->my_hashref_allows_value('bar', 1234), '!my_hashref_allows_value("bar", 1234)' );


### todo... ###

note('TODO: parameterized example with Optional');
note('TODO: parameterized example with slurpy');
note('TODO: parameterized example with slurpy and Optional');
note('TODO: deep coercion');
note('TODO: deep coercion with slurpy');
note('TODO: deep coercion where Optional cannot be coerced');

done_testing;

