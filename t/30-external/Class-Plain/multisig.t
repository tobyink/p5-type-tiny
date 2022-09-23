=pod

=encoding utf-8

=head1 PURPOSE

Check type constraints work with L<Class::Plain>.

=head1 DEPENDENCIES

Test is skipped if Class::Plain 0.02 is not available.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Test::Requires '5.026';
use Test::Requires { "Class::Plain" => 0.02 };

use experimental 'signatures';
use Class::Plain;

class Point {
	use Types::Common -types, -sigs;
	
	field x :reader;
	field y :reader;
	
	signature_for new => (
		method   => !!1,
		multiple => [
			{
				named => [
					x => Int,
					y => Int,
				],
				bless => !!0,
			},
			{
				positional => [ Int, Int ],
				goto_next  => sub {
					my ( $class, $x, $y ) = @_;
					return ( $class, { x => $x, y => $y } ),
				},
			},
		],
	);
	
	method as_arrayref () {
		return [ $self->x, $self->y ];
	}
}

my $point = Point->new( x => 42, y => 666 );

is_deeply(
	$point->as_arrayref,
	[ 42, 666 ],
);

like(
	exception { Point->new( x => 42, y => [] ) },
	qr/Parameter validation failed/,
);

my $point2 = Point->new( 42, 999 );

is_deeply(
	$point2->as_arrayref,
	[ 42, 999 ],
);

done_testing;
