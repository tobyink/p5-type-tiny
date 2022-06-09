=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Tiny's list processing methods.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Types::Standard -types;

my %subtests = (
	'inlineable base types'     => sub { my $type = shift; return $type; },
	'non-inlineable base types' => sub { my $type = shift; return $type->where( sub { 1 } ); },
);

for my $kind ( sort keys %subtests ) {
	
	my $maybe_subtype = $subtests{$kind};
	
	subtest "Tests with $kind" => sub {
		
		my $Rounded2 = Int->$maybe_subtype->plus_coercions( Num, 'int($_)' );
		can_ok( $Rounded2, $_ )
			for qw( grep map sort rsort first any all assert_any assert_all );
		can_ok( Int->$maybe_subtype, $_ )
			for qw( grep     sort rsort first any all assert_any assert_all );
		ok ! Int->$maybe_subtype->can('map');
		
		is_deeply(
			[ Int->$maybe_subtype->grep(qw/ yeah 1 1.5 hello world 2 /, [], qw/ 3 4 5 /, '' ) ],
			[ qw/ 1 2 3 4 5 / ],
			'Int->grep',
		);
		
		is(
			Int->$maybe_subtype->first(qw/ yeah 1.5 hello world 2 /, [], qw/ 3 4 5 /, '' ),
			2,
			'Int->first',
		);
		
		my $e = exception { Int->$maybe_subtype->map( qw/ yeah 1 1.5 hello world 2 /, [], qw/ 3 4 5 /, '' ) };
		like( $e, qr/no coercion/i, 'map() requires a coercion' );
		
		my $Rounded = Int->$maybe_subtype->plus_coercions( Num, sub { int $_ } );
		
		is_deeply(
			[ $Rounded->map( qw/ 1 2.1 3 4 5 / ) ],
			[ qw/ 1 2 3 4 5 / ],
			'$Rounded->map',
		);
		
		is_deeply(
			[ $Rounded->map( qw/ 1 2.1 foo 4 5 / ) ],
			[ qw/ 1 2 foo 4 5 / ],
			'$Rounded->map with uncoercible values',
		);
		
		like(
			exception { Any->$maybe_subtype->sort(qw/ 1 2 3/) },
			qr/No sorter/i,
			'Any->sort',
		);
		
		is_deeply(
			[ Int->$maybe_subtype->sort(qw/ 11 2 1 /) ],
			[ qw/ 1 2 11 / ],
			'Int->sort',
		);
		
		is_deeply(
			[ $Rounded->sort(qw/ 11 2 1 /) ],
			[ qw/ 1 2 11 / ],
			'$Rounded->sort',
		);
		
		is_deeply(
			[ Str->$maybe_subtype->sort(qw/ 11 2 1 /) ],
			[ qw/ 1 11 2 / ],
			'Str->sort',
		);
		
		is_deeply(
			[ Int->$maybe_subtype->rsort(qw/ 11 2 1 /) ],
			[ reverse qw/ 1 2 11 / ],
			'Int->rsort',
		);
		
		is_deeply(
			[ $Rounded->rsort(qw/ 11 2 1 /) ],
			[ reverse qw/ 1 2 11 / ],
			'$Rounded->rsort',
		);
		
		is_deeply(
			[ Str->$maybe_subtype->rsort(qw/ 11 2 1 /) ],
			[ reverse qw/ 1 11 2 / ],
			'Str->rsort',
		);
		
		my $CrazyInt = Int->$maybe_subtype->create_child_type(
			sorter => [ sub { $_[0] cmp $_[1] }, sub { scalar reverse($_[0]) } ],
		);
		
		is_deeply(
			[ $CrazyInt->sort(qw/ 8 56 12 90 80 333 431 /) ],
			[ qw/ 80 90 431 12 333 56 8 / ],
			'$CrazyInt->sort'
		) or diag explain [ $CrazyInt->sort(qw/ 8 56 12 90 80 333 431 /) ];

		is_deeply(
			[ $CrazyInt->rsort(qw/ 8 56 12 90 80 333 431 /) ],
			[ reverse qw/ 80 90 431 12 333 56 8 / ],
			'$CrazyInt->rsort'
		) or diag explain [ $CrazyInt->rsort(qw/ 8 56 12 90 80 333 431 /) ];

		ok(
			! Int->$maybe_subtype->any(qw//),
			'not Int->any(qw//)',
		);
		
		ok(
			Int->$maybe_subtype->any(qw/ foo 1 bar /),
			'Int->any(qw/ foo 1 bar /)',
		);
		
		ok(
			! Int->$maybe_subtype->any(qw/ foo bar /),
			'not Int->any(qw/ foo bar /)',
		);
		
		ok(
			Int->$maybe_subtype->any(qw/ 1 2 3 /),
			'Int->any(qw/ 1 2 3 /)',
		);
		
		ok(
			Int->$maybe_subtype->all(qw//),
			'Int->all(qw//)',
		);
		
		ok(
			! Int->$maybe_subtype->all(qw/ foo 1 bar /),
			'not Int->all(qw/ foo 1 bar /)',
		);
		
		ok(
			! Int->$maybe_subtype->all(qw/ foo bar /),
			'not Int->all(qw/ foo bar /)',
		);
		
		ok(
			Int->$maybe_subtype->all(qw/ 1 2 3 /),
			'Int->all(qw/ 1 2 3 /)',
		);
		
		like(
			exception { Int->$maybe_subtype->assert_any(qw//) },
			qr/Undef did not pass type constraint/,
			'Int->assert_any(qw//) --> exception',
		);
		
		is_deeply(
			[ Int->$maybe_subtype->assert_any(qw/ foo 1 bar /) ],
			[ qw/ foo 1 bar / ],
			'Int->assert_any(qw/ foo 1 bar /)',
		);
		
		like(
			exception { Int->$maybe_subtype->assert_any(qw/ foo bar /) },
			qr/Value "bar" did not pass type constraint/,
			'Int->assert_any(qw/ foo bar /) --> exception',
		);
		
		is_deeply(
			[ Int->$maybe_subtype->assert_any(qw/ 1 2 3 /) ],
			[ qw/ 1 2 3 / ],
			'Int->assert_any(qw/ 1 2 3 /)',
		);
		
		is_deeply(
			[ Int->$maybe_subtype->assert_all(qw//) ],
			[ ],
			'Int->assert_all(qw//)',
		);
		
		like(
			exception { Int->$maybe_subtype->assert_all(qw/ foo 1 bar /) },
			qr/Value "foo" did not pass type constraint/,
			'Int->assert_all(qw/ foo 1 bar /) --> exception',
		);
		
		like(
			exception { Int->$maybe_subtype->assert_all(qw/ foo bar /) },
			qr/Value "foo" did not pass type constraint/,
			'Int->assert_all(qw/ foo bar /) --> exception',
		);
		
		is_deeply(
			[ Int->$maybe_subtype->assert_all(qw/ 1 2 3 /) ],
			[ qw/ 1 2 3 / ],
			'Int->assert_all(qw/ 1 2 3 /)',
		);
		
		like(
			exception { Int->$maybe_subtype->_build_util('xxxx') },
			qr/^Unknown function: xxxx/,
			'Int->_build_util("xxxx") --> exception'
		);
	};
}


done_testing;
