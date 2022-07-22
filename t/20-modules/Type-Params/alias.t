=pod

=encoding utf-8

=head1 PURPOSE

Test C<compile_named> supports parameter aliases.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::More;
use Test::Fatal;
use Types::Standard -types;
use Type::Params qw( compile_named_oo );

{
	my $check;
	sub adder {
		$check ||= compile_named_oo(
			first_number   => Int, { alias => [ 'x' ] },
			second_number  => Int, { alias =>   'y'   },
		);
		my ( $arg ) = &$check;
		my $sum = $arg->first_number + $arg->second_number;
		wantarray ? ( $sum, $arg ) : $sum;
	}
}

is( adder( first_number => 40, second_number => 2 ), 42, 'real args' );

is( adder( x => 40, y => 3 ), 43, 'aliases for args' );

is( adder( first_number => 40, y => 4 ), 44, 'mixed 1' );

is( adder( x => 40, second_number => 5 ), 45, 'mixed 2' );

is( adder( { x => 60, y => 3 } ), 63, 'hashref' );

my $e1 = exception{
	adder( { first_number => 40, x => 41, y => 2 } );
};

like $e1, qr/Superfluous alias "x" for argument "first_number"/, 'error';

my ( $sum, $arg ) = adder( x => 1, y => 2 );
is_deeply(
	[ grep !/caller/, sort keys %$arg ],
	[ 'first_number', 'second_number' ],
	'correct hash keys in $arg',
);
can_ok( $arg, 'first_number', 'second_number' );
ok !$arg->can( 'x' ), 'no method "x"';
ok !$arg->can( 'y' ), 'no method "y"';

done_testing;
