=pod

=encoding utf-8

=head1 PURPOSE

Type::Params's C<optional> and C<slurpy> together.

=head1 SEE ALSO

L<https://github.com/tobyink/p5-type-tiny/issues/140>.

=head1 AUTHOR

XSven L<https://github.com/XSven>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023 by XSven.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Types::Common -types, -sigs;

use Test::Requires { 'Test::Warnings' => 0.005 };
use Test::Warnings ':all';

my $sig;
sub add_nums {
	$sig ||= signature(
		positional => [
			Num,
			ArrayRef[Num,1], { optional => !!1, slurpy => !!1 },
		],
	);
	my ( $first_num, $other_nums ) = $sig->( @_ );

	my $sum = $first_num;
	$sum += $_ for @$other_nums;

	return $sum;
}

my $w = warning {
	is add_nums( 1, 0 ), 1;
};

like $w, qr/^Warning: the optional for the slurpy parameter will be ignored, continuing anyway/;

done_testing;
