=pod

=encoding utf-8

=head1 PURPOSE

Basic tests for B<NegativeOrZeroInt> from L<Types::Common::Numeric>.

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
use Types::Common::Numeric qw( NegativeOrZeroInt );

isa_ok(NegativeOrZeroInt, 'Type::Tiny', 'NegativeOrZeroInt');
is(NegativeOrZeroInt->name, 'NegativeOrZeroInt', 'NegativeOrZeroInt has correct name');
is(NegativeOrZeroInt->display_name, 'NegativeOrZeroInt', 'NegativeOrZeroInt has correct display_name');
is(NegativeOrZeroInt->library, 'Types::Common::Numeric', 'NegativeOrZeroInt knows it is in the Types::Common::Numeric library');
ok(Types::Common::Numeric->has_type('NegativeOrZeroInt'), 'Types::Common::Numeric knows it has type NegativeOrZeroInt');
ok(!NegativeOrZeroInt->deprecated, 'NegativeOrZeroInt is not deprecated');
ok(!NegativeOrZeroInt->is_anon, 'NegativeOrZeroInt is not anonymous');
ok(NegativeOrZeroInt->can_be_inlined, 'NegativeOrZeroInt can be inlined');
is(exception { NegativeOrZeroInt->inline_check(q/$xyz/) }, undef, "Inlining NegativeOrZeroInt doesn't throw an exception");
ok(!NegativeOrZeroInt->has_coercion, "NegativeOrZeroInt doesn't have a coercion");
ok(!NegativeOrZeroInt->is_parameterizable, "NegativeOrZeroInt isn't parameterizable");

my @tests = (
	todo => 'undef'                    => undef,
	todo => 'false'                    => !!0,
	todo => 'true'                     => !!1,
	todo => 'zero'                     =>  0,
	todo => 'one'                      =>  1,
	todo => 'negative one'             => -1,
	todo => 'non integer'              =>  3.1416,
	todo => 'empty string'             => '',
	todo => 'whitespace'               => ' ',
	todo => 'line break'               => "\n",
	todo => 'random string'            => 'abc123',
	todo => 'loaded package name'      => 'Type::Tiny',
	todo => 'unloaded package name'    => 'This::Has::Probably::Not::Been::Loaded',
	todo => 'a reference to undef'     => do { my $x = undef; \$x },
	todo => 'a reference to false'     => do { my $x = !!0; \$x },
	todo => 'a reference to true'      => do { my $x = !!1; \$x },
	todo => 'a reference to zero'      => do { my $x = 0; \$x },
	todo => 'a reference to one'       => do { my $x = 1; \$x },
	todo => 'a reference to empty string' => do { my $x = ''; \$x },
	todo => 'a reference to random string' => do { my $x = 'abc123'; \$x },
	todo => 'blessed scalarref'        => bless(do { my $x = undef; \$x }, 'SomePkg'),
	todo => 'empty arrayref'           => [],
	todo => 'arrayref with one zero'   => [0],
	todo => 'arrayref of integers'     => [1..10],
	todo => 'arrayref of numbers'      => [1..10, 3.1416],
	todo => 'blessed arrayref'         => bless([], 'SomePkg'),
	todo => 'empty hashref'            => {},
	todo => 'hashref'                  => { foo => 1 },
	todo => 'blessed hashref'          => bless({}, 'SomePkg'),
	todo => 'coderef'                  => sub { 1 },
	todo => 'blessed coderef'          => bless(sub { 1 }, 'SomePkg'),
	todo => 'glob'                     => do { no warnings 'once'; *SOMETHING },
	todo => 'globref'                  => do { no warnings 'once'; my $x = *SOMETHING; \$x },
	todo => 'blessed globref'          => bless(do { no warnings 'once'; my $x = *SOMETHING; \$x }, 'SomePkg'),
	todo => 'regexp'                   => qr/./,
	todo => 'blessed regexp'           => bless(qr/./, 'SomePkg'),
	todo => 'filehandle'               => do { open my $x, '<', $0 or die; $x },
	todo => 'filehandle object'        => do { require IO::File; 'IO::File'->new($0, 'r') },
	todo => 'ref to scalarref'         => do { my $x = undef; my $y = \$x; \$y },
	todo => 'ref to arrayref'          => do { my $x = []; \$x },
	todo => 'ref to hashref'           => do { my $x = {}; \$x },
	todo => 'ref to coderef'           => do { my $x = sub { 1 }; \$x },
	todo => 'ref to blessed hashref'   => do { my $x = bless({}, 'SomePkg'); \$x },
);

while (@tests) {
	my ($expect, $label, $value) = splice(@tests, 0 , 3);
	if ($expect eq 'todo') {
		note("TODO: $label");
	}
	elsif ($expect eq 'pass') {
		should_pass($value, NegativeOrZeroInt, ucfirst("$label should pass NegativeOrZeroInt"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, NegativeOrZeroInt, ucfirst("$label should fail NegativeOrZeroInt"));
	}
	else {
		fail("expected '$expect'?!");
	}
}

done_testing;

