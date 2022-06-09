=pod

=encoding utf-8

=head1 PURPOSE

Adopted test from Kavorka test suite.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use utf8;
use warnings;
use Test::More;
use Test::Fatal;

BEGIN {
	$ENV{AUTOMATED_TESTING}
	or $ENV{EXTENDED_TESTING}
	or $ENV{AUTHOR_TESTING}
	or $ENV{RELEASE_TESTING}
	or plan skip_all => 'EXTENDED_TESTING';
	eval {
		local $SIG{__WARN__} = sub {};
		require Kavorka; 'Kavorka'->import; 1;
	} or plan skip_all => 'requires Kavorka';
};

note "simple type constraint";

fun add1 ($a, $b → Int) {
	return $a + $b;
}

is( add1(4,5), 9 );
is( add1(4.1,4.9), 9 );
like(exception { my $r = add1(4.1, 5) }, qr{did not pass type constraint "Int" at \S+ line 48});

is_deeply( [add1(4,5)], [9] );
like(exception { my @r = add1(4.1, 5) }, qr{did not pass type constraint "ArrayRef.Int." at \S+ line 51});

note "type constraint expression";

use Types::Standard ();
use constant Rounded => Types::Standard::Int()->plus_coercions(Types::Standard::Num(), q[int($_)]);

fun add2 ($a, $b --> (Rounded) does coerce) {
	return $a + $b;
}

is( add2(4,5), 9 );
is( add2(4.1,4.9), 9 );
is( add2(4.1,5), 9 );

note "type constraints for list and scalar contexts";

fun add3 ($a, $b → Int, ArrayRef[Int] is list) {
	wantarray ? ($a,$b) : ($a+$b);
}

is( add3(4,5), 9 );
is( add3(4.1,4.9), 9 );
like(exception { my $r = add3(4.1, 5) }, qr{did not pass type constraint "Int" at \S+ line 74});

is_deeply( [add3(4,5)], [4,5] );
like(exception { my @r = add3(4.1,4.9) }, qr{did not pass type constraint "ArrayRef.Int." at \S+ line 77});
like(exception { my @r = add3(4.1,5) }, qr{did not pass type constraint "ArrayRef.Int." at \S+ line 78});

done_testing;
