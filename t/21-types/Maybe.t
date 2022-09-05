=pod

=encoding utf-8

=head1 PURPOSE

Basic tests for B<Maybe> from L<Types::Standard>.

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
use Types::Standard qw( Maybe );

isa_ok(Maybe, 'Type::Tiny', 'Maybe');
is(Maybe->name, 'Maybe', 'Maybe has correct name');
is(Maybe->display_name, 'Maybe', 'Maybe has correct display_name');
is(Maybe->library, 'Types::Standard', 'Maybe knows it is in the Types::Standard library');
ok(Types::Standard->has_type('Maybe'), 'Types::Standard knows it has type Maybe');
ok(!Maybe->deprecated, 'Maybe is not deprecated');
ok(!Maybe->is_anon, 'Maybe is not anonymous');
ok(Maybe->can_be_inlined, 'Maybe can be inlined');
is(exception { Maybe->inline_check(q/$xyz/) }, undef, "Inlining Maybe doesn't throw an exception");
ok(!Maybe->has_coercion, "Maybe doesn't have a coercion");
ok(Maybe->is_parameterizable, "Maybe is parameterizable");
isnt(Maybe->type_default, undef, "Maybe has a type_default");
is(Maybe->type_default->(), undef, "Maybe type_default is undef");

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
		should_pass($value, Maybe, ucfirst("$label should pass Maybe"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, Maybe, ucfirst("$label should fail Maybe"));
	}
	else {
		fail("expected '$expect'?!");
	}
}

#
# Maybe[X] is an undef-tolerant version of X.
#

my $type = Maybe[ Types::Standard::Int ];
should_pass(0, $type);
should_pass(1, $type);
should_fail(1.1, $type);
should_pass(undef, $type);

isnt($type->type_default, undef, "$type has a type_default, because Int does");
is($type->type_default->(), 0, "$type type_default is 0");

my $type2 = Maybe[ Types::Standard::Defined ];
isnt($type2->type_default, undef, "$type2 has a type_default, even though Defined doesn't");
is($type2->type_default->(), undef, "$type2 type_default is undef");

done_testing;

