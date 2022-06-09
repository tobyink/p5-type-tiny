=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Tiny works with L<Kavorka>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::Requires 'Kavorka';
use Test::Fatal;

use Kavorka;
use Types::Standard qw(Int Num);

fun xyz (
	Int $x,
	(Int) $y,
	(Int->plus_coercions(Num, 'int($_)')) $z does coerce
) {
	$x * $y * $z;
}

is(
	exception {
		is(
			xyz(2,3,4),
			24,
			'easy sub call; all type constraints should pass',
		);
		is(
			xyz(2,3,4.2),
			24,
			'easy sub call; all type constraints should pass or coerce',
		);
	},
	undef,
	'... neither raise an exception',
);

isnt(
	exception { xyz(2.1,3,4) },
	undef,
	'failed type constraint with no coercion raises an exception',
);

done_testing;
