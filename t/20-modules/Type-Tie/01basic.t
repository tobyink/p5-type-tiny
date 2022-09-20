=pod

=encoding utf-8

=head1 PURPOSE

Test that Type::Tie compiles and seems to work.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2018-2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Type::Tie;
use Types::Standard qw( Int Num );

ttie my $count, Int, 0;

$count++;            is($count, 1);
$count = 2;          is($count, 2);

like(
	exception { $count = "Monkey!" },
	qr{^Value "Monkey!" did not pass type constraint "Int"},
);

ttie my @numbers, Int, 1, 2, 3;

unshift @numbers, 0;
$numbers[4] = 4;
push @numbers, scalar @numbers;

is_deeply(
	\@numbers,
	[ 0..5 ],
);

like(
	exception { push @numbers, 1, 2, 3, "Bad", 4 },
	qr{^Value "Bad" did not pass type constraint "Int"},
);

like(
	exception { unshift @numbers, 1, 2, 3, "Bad", 4 },
	qr{^Value "Bad" did not pass type constraint "Int"},
);

like(
	exception { $numbers[2] .= "Bad" },
	qr{^Value "2Bad" did not pass type constraint "Int"},
);

is_deeply(
	\@numbers,
	[ 0..5 ],
);

ttie my %stuff, Int, foo => 1;
$stuff{bar} = 2;

is_deeply(
	\%stuff,
	{ foo => 1, bar => 2 },
);

like(
	exception { $stuff{baz} = undef },
	qr{^Undef did not pass type constraint "Int"},
);

delete $stuff{bar};

is_deeply(
	\%stuff,
	{ foo => 1 },
);

done_testing;
