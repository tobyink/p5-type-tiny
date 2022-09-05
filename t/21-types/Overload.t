=pod

=encoding utf-8

=head1 PURPOSE

Basic tests for B<Overload> from L<Types::Standard>.

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
use Types::Standard qw( Overload );

isa_ok(Overload, 'Type::Tiny', 'Overload');
is(Overload->name, 'Overload', 'Overload has correct name');
is(Overload->display_name, 'Overload', 'Overload has correct display_name');
is(Overload->library, 'Types::Standard', 'Overload knows it is in the Types::Standard library');
ok(Types::Standard->has_type('Overload'), 'Types::Standard knows it has type Overload');
ok(!Overload->deprecated, 'Overload is not deprecated');
ok(!Overload->is_anon, 'Overload is not anonymous');
ok(Overload->can_be_inlined, 'Overload can be inlined');
is(exception { Overload->inline_check(q/$xyz/) }, undef, "Inlining Overload doesn't throw an exception");
ok(!Overload->has_coercion, "Overload doesn't have a coercion");
ok(Overload->is_parameterizable, "Overload is parameterizable");
is(Overload->type_default, undef, "Overload has no type_default");

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
		should_pass($value, Overload, ucfirst("$label should pass Overload"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, Overload, ucfirst("$label should fail Overload"));
	}
	else {
		fail("expected '$expect'?!");
	}
}

#
# Type::Tiny itself overloads q[&{}] and q[""] but not q[${}].
#

should_pass(Overload, Overload[ q[&{}] ]);
should_pass(Overload, Overload[ q[""] ]);
should_fail(Overload, Overload[ q[${}] ]);

#
# It's possible to check multiple overloaded operations.
#

should_pass(Overload, Overload[ q[&{}], q[""] ]);
should_fail(Overload, Overload[ q[""], q[${}] ]);
should_fail(Overload, Overload[ q[&{}], q[${}] ]);

#
# In the following example, $fortytwo_withfallback doesn't overload
# '+' but still passes Overload['+'] because it provides a numification
# overload and allows fallbacks.
#

my $fortytwo_nofallback = do {
	package Local::OL::NoFallback;
	use overload q[0+] => sub { ${$_[0]} };
	my $x = 42;
	bless \$x;
};

my $fortytwo_withfallback = do {
	package Local::OL::WithFallback;
	use overload q[0+] => sub { ${$_[0]} }, fallback => 1;
	my $x = 42;
	bless \$x;
};

should_pass($fortytwo_nofallback, Overload['0+']);
should_pass($fortytwo_withfallback, Overload['0+']);
should_fail($fortytwo_nofallback, Overload['+']);
should_fail($fortytwo_withfallback, Overload['+']);

done_testing;

