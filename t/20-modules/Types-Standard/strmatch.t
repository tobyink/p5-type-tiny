=pod

=encoding utf-8

=head1 PURPOSE

Checks various values against C<StrMatch> from Types::Standard.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( . ./t ../inc ./inc );

use Test::More;
use Test::TypeTiny;
use Test::Fatal;

use Types::Standard -all, "slurpy";
use Type::Utils;

my $e = exception { StrMatch[{}] };
like($e, qr/^First parameter to StrMatch\[\`a\] expected to be a Regexp/, 'error message 1');

$e = exception { StrMatch[qr/(.)/, []] };
like($e, qr/^Second parameter to StrMatch\[\`a\] expected to be a type constraint/, 'error message 2');

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

my $Boolean = declare Boolean => as StrMatch[qr{^(?:true|false|0|1)$}ism];
should_pass("true", $Boolean);
should_pass("True", $Boolean);
should_pass("TRUE", $Boolean);
should_pass("false", $Boolean);
should_pass("False", $Boolean);
should_pass("FALSE", $Boolean);
should_pass("0", $Boolean);
should_pass("1", $Boolean);
should_fail("True ", $Boolean);
should_fail("11", $Boolean);

my $SecureUrl = declare SecureUrl => as StrMatch[qr{^https://}];
should_pass("https://www.google.com/", $SecureUrl);
should_fail("http://www.google.com/", $SecureUrl);

my $length_eq_3 = StrMatch[qr/\A...\z/];
should_fail('ab', $length_eq_3);
should_pass('abc', $length_eq_3);
should_fail('abcd', $length_eq_3);
#diag( $length_eq_3->inline_check('$x') );

my $length_ge_3 = StrMatch[qr/\A.../];
should_fail('ab', $length_ge_3);
should_pass('abc', $length_ge_3);
should_pass('abcd', $length_ge_3);
#diag( $length_ge_3->inline_check('$x') );

done_testing;
