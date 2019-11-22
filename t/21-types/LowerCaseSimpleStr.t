=pod

=encoding utf-8

=head1 PURPOSE

Basic tests for B<LowerCaseSimpleStr> from L<Types::Common::String>.

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
use Types::Common::String qw( LowerCaseSimpleStr );

isa_ok(LowerCaseSimpleStr, 'Type::Tiny', 'LowerCaseSimpleStr');
is(LowerCaseSimpleStr->name, 'LowerCaseSimpleStr', 'LowerCaseSimpleStr has correct name');
is(LowerCaseSimpleStr->display_name, 'LowerCaseSimpleStr', 'LowerCaseSimpleStr has correct display_name');
is(LowerCaseSimpleStr->library, 'Types::Common::String', 'LowerCaseSimpleStr knows it is in the Types::Common::String library');
ok(Types::Common::String->has_type('LowerCaseSimpleStr'), 'Types::Common::String knows it has type LowerCaseSimpleStr');
ok(!LowerCaseSimpleStr->deprecated, 'LowerCaseSimpleStr is not deprecated');
ok(!LowerCaseSimpleStr->is_anon, 'LowerCaseSimpleStr is not anonymous');
ok(LowerCaseSimpleStr->can_be_inlined, 'LowerCaseSimpleStr can be inlined');
is(exception { LowerCaseSimpleStr->inline_check(q/$xyz/) }, undef, "Inlining LowerCaseSimpleStr doesn't throw an exception");
ok(LowerCaseSimpleStr->has_coercion, "LowerCaseSimpleStr has a coercion");
ok(!LowerCaseSimpleStr->is_parameterizable, "LowerCaseSimpleStr isn't parameterizable");

my @tests = (
	fail => 'undef'                    => undef,
	fail => 'false'                    => !!0,
	pass => 'true'                     => !!1,
	pass => 'zero'                     =>  0,
	pass => 'one'                      =>  1,
	pass => 'negative one'             => -1,
	pass => 'non integer'              =>  3.1416,
	fail => 'empty string'             => '',
	pass => 'whitespace'               => ' ',
	fail => 'line break'               => "\n",
	pass => 'random string'            => 'abc123',
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
);

while (@tests) {
	my ($expect, $label, $value) = splice(@tests, 0 , 3);
	if ($expect eq 'todo') {
		note("TODO: $label");
	}
	elsif ($expect eq 'pass') {
		should_pass($value, LowerCaseSimpleStr, ucfirst("$label should pass LowerCaseSimpleStr"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, LowerCaseSimpleStr, ucfirst("$label should fail LowerCaseSimpleStr"));
	}
	else {
		fail("expected '$expect'?!");
	}
}

note("TODO: write tests for coercions");

done_testing;
