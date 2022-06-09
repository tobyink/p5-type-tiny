=pod

=encoding utf-8

=head1 PURPOSE

Tests constraints for L<Types::Common::Numeric>'s
C<IntRange> and C<NumRange>.

=head1 AUTHOR

Toby Inkster.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018-2022 by Toby Inkster.
 
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::TypeTiny qw( -all );
use Test::Fatal;

BEGIN {
	plan skip_all => "https://github.com/perl11/cperl/issues/409" if "$^V" =~ /c$/;
};

use Types::Common::Numeric -all;

should_fail($_, IntRange[10,15]) for -19 .. +9;
should_pass($_, IntRange[10,15]) for  10 .. 15;
should_fail($_, IntRange[10,15]) for  16 .. 20;

should_fail($_ + 0.5, IntRange[10,15]) for -9 .. 20;

should_fail($_, IntRange[10,15]) for ([], {}, sub { 3 }, "hello world");

should_fail($_, IntRange[10]) for -19 .. 9;
should_pass($_, IntRange[10]) for  10 .. 24, 1000, 1_000_000;

###########

should_fail($_, NumRange[10,15]) for -19 .. +9;
should_pass($_, NumRange[10,15]) for  10 .. 15;
should_fail($_, NumRange[10,15]) for  16 .. 20;

should_fail($_ + 0.5, NumRange[10,15]) for -9 .. 9;
should_pass($_ + 0.5, NumRange[10,15]) for  10 .. 14;
should_fail($_ + 0.5, NumRange[10,15]) for  15 .. 20;

should_fail($_, NumRange[10,15]) for ([], {}, sub { 3 }, "hello world");

should_fail($_, NumRange[10]) for -19 .. 9;
should_pass($_, NumRange[10]) for  10 .. 24, 1000, 1_000_000;

###########

should_fail(  '9.99', NumRange[10,15,0,0] );
should_pass( '10.00', NumRange[10,15,0,0] );
should_pass( '10.01', NumRange[10,15,0,0] );
should_pass( '12.50', NumRange[10,15,0,0] );
should_pass( '14.99', NumRange[10,15,0,0] );
should_pass( '15.00', NumRange[10,15,0,0] );
should_fail( '15.01', NumRange[10,15,0,0] );

should_fail(  '9.99', NumRange[10,15,1,0] );
should_fail( '10.00', NumRange[10,15,1,0] );
should_pass( '10.01', NumRange[10,15,1,0] );
should_pass( '12.50', NumRange[10,15,1,0] );
should_pass( '14.99', NumRange[10,15,1,0] );
should_pass( '15.00', NumRange[10,15,1,0] );
should_fail( '15.01', NumRange[10,15,1,0] );

should_fail(  '9.99', NumRange[10,15,0,1] );
should_pass( '10.00', NumRange[10,15,0,1] );
should_pass( '10.01', NumRange[10,15,0,1] );
should_pass( '12.50', NumRange[10,15,0,1] );
should_pass( '14.99', NumRange[10,15,0,1] );
should_fail( '15.00', NumRange[10,15,0,1] );
should_fail( '15.01', NumRange[10,15,0,1] );

should_fail(  '9.99', NumRange[10,15,1,1] );
should_fail( '10.00', NumRange[10,15,1,1] );
should_pass( '10.01', NumRange[10,15,1,1] );
should_pass( '12.50', NumRange[10,15,1,1] );
should_pass( '14.99', NumRange[10,15,1,1] );
should_fail( '15.00', NumRange[10,15,1,1] );
should_fail( '15.01', NumRange[10,15,1,1] );

###########

should_pass(1, IntRange);
should_fail($_, IntRange) for ([], {}, sub { 3 }, "hello world", '1.2345');

should_pass(1, NumRange);
should_fail($_, NumRange) for ([], {}, sub { 3 }, "hello world");
should_pass('1.2345', NumRange);

###########

foreach my $test (
	[NumRange, [{}, 5], qr/NumRange min must be a num/, "NumRange non-numeric min"],
	[NumRange, [5, {}], qr/NumRange max must be a num/, "NumRange non-numeric max"],
	[NumRange, [5, 10, {}], qr/NumRange minexcl must be a boolean/, "NumRange non-boolean minexcl"],
	[NumRange, [5, 10, 0, {}], qr/NumRange maxexcl must be a boolean/, "NumRange non-boolean maxexcl"],
	[NumRange, [{}, {}], qr/NumRange min must be a num/, "NumRange non-numeric min and max"],
	[IntRange, [{}, 5], qr/IntRange min must be a int/, "IntRange non-numeric min"],
	[IntRange, [5, {}], qr/IntRange max must be a int/, "IntRange non-numeric max"],
	[IntRange, [5, 10, {}], qr/IntRange minexcl must be a boolean/, "IntRange non-boolean minexcl"],
	[IntRange, [5, 10, 0, {}], qr/IntRange maxexcl must be a boolean/, "IntRange non-boolean maxexcl"],
	[IntRange, [{}, {}], qr/IntRange min must be a int/, "IntRange non-numeric min and max"],
	[IntRange, [1.1, 5], qr/IntRange min must be a int/, "IntRange non-integer min"],
	[IntRange, [5, 9.9], qr/IntRange max must be a int/, "IntRange non-integer max"],
) {
	my ($base, $params, $qr, $desc) = @$test;
	my $e = exception { $base->of(@$params) };
	like($e, $qr, "Exception thrown for $desc");
}

done_testing;
