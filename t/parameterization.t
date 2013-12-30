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

This software is copyright (c) 2013-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::TypeTiny -all;

use Types::Standard -types;

my $p1 = ArrayRef[Int];
my $p2 = ArrayRef[Int];
my $p3 = ArrayRef[Int->create_child_type()];

is($p1->{uniq}, $p2->{uniq}, "Avoid duplicating parameterized types");
isnt($p1->{uniq}, $p3->{uniq}, "... except when necessary!");

=pod

=begin not_yet_implemented

my $p4 = ArrayRef[sub { $_ eq "Bob" }];
my $p5 = ArrayRef[sub { $_ eq "Bob" or die "not Bob" }];

should_pass(["Bob"], $p4);
should_pass(["Bob", "Bob"], $p4);
should_fail(["Bob", "Bob", "Suzie"], $p4);

should_pass(["Bob"], $p5);
should_pass(["Bob", "Bob"], $p5);
should_fail(["Bob", "Bob", "Suzie"], $p5);

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

=end not_yet_implemented

=cut

done_testing;
