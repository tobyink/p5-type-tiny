=pod

=encoding utf-8

=head1 PURPOSE

There are loads of tests for parameterization in C<stdlib.t>,
C<stdlib-overload.t>, C<stdlib-strmatch.t>, C<stdlib-structures.t>, 
C<syntax.t>, C<stdlib-automatic.t>, etc. This file includes a handful
of other parameterization-related tests that didn't fit anywhere
else.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::TypeTiny -all;
use Test::Fatal;

use Types::Standard qw/ -types slurpy /;

my $p1 = ArrayRef[Int];
my $p2 = ArrayRef[Int];
my $p3 = ArrayRef[Int->create_child_type()];

is($p1->{uniq}, $p2->{uniq}, "Avoid duplicating parameterized types");
isnt($p1->{uniq}, $p3->{uniq}, "... except when necessary!");

my $p4 = ArrayRef[sub { $_ eq "Bob" }];
my $p5 = ArrayRef[sub { $_ eq "Bob" or die "not Bob" }];
my $p6 = ArrayRef[Str & +sub { $_ eq "Bob" or die "not Bob" }];

should_pass(["Bob"], $p4);
should_pass(["Bob", "Bob"], $p4);
should_fail(["Bob", "Bob", "Suzie"], $p4);

should_pass(["Bob"], $p5);
should_pass(["Bob", "Bob"], $p5);
should_fail(["Bob", "Bob", "Suzie"], $p5);

should_pass(["Bob"], $p6);
should_pass(["Bob", "Bob"], $p6);
should_fail(["Bob", "Bob", "Suzie"], $p6);

is(
	$p4->parameters->[0]->validate("Suzie"),
	'Value "Suzie" did not pass type constraint',
	'error message when a coderef returns false',
);

like(
	$p5->parameters->[0]->validate("Suzie"),
	qr{^not Bob},
	'error message when a coderef dies',
);

my $p7 = ArrayRef[Dict[foo =>Int, slurpy Any]];
my $p8 = ArrayRef[Dict[foo =>Int, slurpy Any]];
is($p7->inline_check(q/$X/), $p8->inline_check(q/$X/), '$p7 and $p8 stringify the same');
is($p7->{uniq}, $p8->{uniq}, '$p7 and $p8 are the same');

is(
	Type::Tiny::____make_key( [ 1..5, \0, [ { foo => undef, bar => Int } ] ] ),
	'["1","2","3","4","5",\("0"),[{"bar",$Type::Tiny::ALL_TYPES{' . Int->{uniq} . '},"foo",undef}]]',
);

done_testing;
