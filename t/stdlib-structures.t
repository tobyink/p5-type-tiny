=pod

=encoding utf-8

=head1 PURPOSE

Checks various values against structured types from Type::Standard.

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

use Type::Standard -all, "slurpy";

sub should_pass
{
	my ($value, $type) = @_;
	@_ = (
		!!$type->check($value),
		defined $value
			? sprintf("value '%s' passes type constraint '%s'", $value, $type)
			: sprintf("undef passes type constraint '%s'", $type),
	);
	goto \&Test::More::ok;
}

sub should_fail
{
	my ($value, $type) = @_;
	@_ = (
		!$type->check($value),
		defined $value
			? sprintf("value '%s' fails type constraint '%s'", $value, $type)
			: sprintf("undef fails type constraint '%s'", $type),
	);
	goto \&Test::More::ok;
}

my $struct1 = Map[Int, Num];

should_pass({1=>111,2=>222}, $struct1);
should_pass({1=>1.1,2=>2.2}, $struct1);
should_fail({1=>"Str",2=>222}, $struct1);
should_fail({1.1=>1,2=>2.2}, $struct1);

my $struct2 = Tuple[Int, Num, Optional([Int]), slurpy ArrayRef[Num]];
my $struct3 = Tuple[Int, Num, Optional[Int]];

should_pass([1, 1.1], $struct2);
should_pass([1, 1.1, 2], $struct2);
should_pass([1, 1.1, 2, 2.2], $struct2);
should_pass([1, 1.1, 2, 2.2, 2.3], $struct2);
should_pass([1, 1.1, 2, 2.2, 2.3, 2.4], $struct2);
should_fail({}, $struct2);
should_fail([], $struct2);
should_fail([1], $struct2);
should_fail([1.1, 1.1], $struct2);
should_fail([1, 1.1, 2.1], $struct2);
should_fail([1, 1.1, 2.1], $struct2);
should_fail([1, 1.1, 2, 2.2, 2.3, 2.4, "xyz"], $struct2);
should_fail([1, 1.1, undef], $struct2);
should_pass([1, 1.1], $struct3);
should_pass([1, 1.1, 2], $struct3);
should_fail([1, 1.1, 2, 2.2], $struct3);
should_fail([1, 1.1, 2, 2.2, 2.3], $struct3);
should_fail([1, 1.1, 2, 2.2, 2.3, 2.4], $struct3);
should_fail({}, $struct3);
should_fail([], $struct3);
should_fail([1], $struct3);
should_fail([1.1, 1.1], $struct3);
should_fail([1, 1.1, 2.1], $struct3);
should_fail([1, 1.1, 2.1], $struct3);
should_fail([1, 1.1, 2, 2.2, 2.3, 2.4, "xyz"], $struct3);
should_fail([1, 1.1, undef], $struct3);

my $struct4 = Dict[ name => Str, age => Int, height => Optional[Num] ];

should_pass({ name => "Bob", age => 40, height => 1.76 }, $struct4);
should_pass({ name => "Bob", age => 40 }, $struct4);
should_fail({ name => "Bob" }, $struct4);
should_fail({ age => 40 }, $struct4);
should_fail({ name => "Bob", age => 40.1 }, $struct4);
should_fail({ name => "Bob", age => 40, weight => 80.3 }, $struct4);
should_fail({ name => "Bob", age => 40, height => 1.76, weight => 80.3 }, $struct4);
should_fail({ name => "Bob", age => 40, height => "xyz" }, $struct4);

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
