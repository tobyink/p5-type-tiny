=pod

=encoding utf-8

=head1 PURPOSE

Checks various values against C<StrMatch> from Type::Standard.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( . ./t ../inc ./inc );

use Test::More;
use Test::TypeTiny;

use Type::Standard -all, "slurpy";
use Type::Utils;

my $DistanceUnit = enum DistanceUnit => [qw/ mm cm m km /];
my $Distance = declare Distance => as StrMatch[
	qr{^([0-9]+)\s+(.+)$},
	Tuple[Int, $DistanceUnit],
];

should_pass("mm", $DistanceUnit);
should_pass("cm", $DistanceUnit);
should_pass("m", $DistanceUnit);
should_pass("km", $DistanceUnit);
should_fail("MM", $DistanceUnit);
should_fail("mm ", $DistanceUnit);
should_fail(" mm", $DistanceUnit);
should_fail("miles", $DistanceUnit);

should_pass("5 km", $Distance) or diag($Distance->inline_check('$XXX'));
should_pass("5 mm", $Distance);
should_fail("4 miles", $Distance);
should_fail("5.5 km", $Distance);
should_fail([qw/5 km/], $Distance);

done_testing;
