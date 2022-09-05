=pod

=encoding utf-8

=head1 PURPOSE

Tests L<Types::Common>.

=head1 AUTHOR

Toby Inkster.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.
 
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings FATAL => 'all';
use Test::More;

{
	my %imported;
	use Types::Common { into => \%imported }, -all;

	my @libs = qw(
		Types::Standard
		Types::Common::Numeric
		Types::Common::String
		Types::TypeTiny
	);
	my @types     = map $_->type_names, @libs;
	my @coercions = map $_->coercion_names, @libs;

	is_deeply(
		[ sort keys %imported ],
		[ sort { $a cmp $b } (
			@types,
			map( "assert_$_", @types ),
			map( "is_$_", @types ),
			map( "to_$_", @types ),
			@coercions,
			@{ $Type::Params::EXPORT_TAGS{sigs} || [] },
			qw( t ),
		) ],
		'correct imports',
	);

	ok( $imported{t}->( 'Str' ) == Types::Standard::Str(), 't() is preloaded' );
}

done_testing;
