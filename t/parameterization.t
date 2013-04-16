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

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;

use Types::Standard -types;

my $p1 = ArrayRef[Int];
my $p2 = ArrayRef[Int];
my $p3 = ArrayRef[Int->create_child_type()];

is($p1->{uniq}, $p2->{uniq}, "Avoid duplicating parameterized types");
isnt($p1->{uniq}, $p3->{uniq}, "... except when necessary!");

done_testing;
