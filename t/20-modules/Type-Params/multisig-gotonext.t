=pod

=encoding utf-8

=head1 PURPOSE

Test L<Type::Params> C<multi> signatures work with C<goto_next>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023-2024 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

BEGIN {
	package MyTest;
	use Types::Common -sigs, -types;
	signature_for f => (
		method   => Str,
		multiple => [
			{
				named => [
					x     => Num,
					y     => Num,
					note  => Str, { default => '(no note)' },
				],
				named_to_list => 1,
			},
			{
				positional => [ Num, Num, Str, { default => '(no note)' } ],
			},
			{
				positional => [ Tuple[ Num, Num ], Str, { default => '(no note)' } ],
				goto_next  => sub {
					my ( $class, $xy, $note ) = @_;
					my ( $x, $y ) = @{ $xy };
					return ( $class, $x, $y, $note );
				},
			},
		],
	);
	sub f {
		my ( $class, $x, $y, $note ) = @_;
		$class eq __PACKAGE__ or die;
		return {
			x     => $x,
			y     => $y,
			note  => $note,
		};
	}
}

is_deeply(
	MyTest->f( x => 1, y => 2, note => 'foo' ),
	{ x => 1, y => 2, note => 'foo' },
	"MyTest->f( x => 1, y => 2, note => 'foo' )",
);

is_deeply(
	MyTest->f( x => 3, y => 4 ),
	{ x => 3, y => 4, note => '(no note)' },
	"MyTest->f( x => 3, y => 4 )",
);

is_deeply(
	MyTest->f( { x => 1, y => 2, note => 'foo' } ),
	{ x => 1, y => 2, note => 'foo' },
	"MyTest->f( { x => 1, y => 2, note => 'foo' } )",
);

is_deeply(
	MyTest->f( { x => 3, y => 4 } ),
	{ x => 3, y => 4, note => '(no note)' },
	"MyTest->f( { x => 3, y => 4 } )",
);

is_deeply(
	MyTest->f( 1, 2, 'foo' ),
	{ x => 1, y => 2, note => 'foo' },
	"MyTest->f( 1, 2, 'foo' )",
);

is_deeply(
	MyTest->f( 3, 4 ),
	{ x => 3, y => 4, note => '(no note)' },
	"MyTest->f( 3, 4 )",
);

is_deeply(
	MyTest->f( [ 5, 6 ], 'foo' ),
	{ x => 5, y => 6, note => 'foo' },
	"MyTest->f( [ 5, 6 ], 'foo' )",
);

is_deeply(
	MyTest->f( [ 7, 8 ] ),
	{ x => 7, y => 8, note => '(no note)' },
	"MyTest->f( [ 7, 8 ] )",
);

done_testing;

