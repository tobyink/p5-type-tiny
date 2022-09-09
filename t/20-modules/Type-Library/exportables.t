=pod

=encoding utf-8

=head1 PURPOSE

Tests correct things are exported by type libraries.

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
use Test::Requires 'Test::Deep';

BEGIN {
	package My::Types;
	use Type::Library -base, -utils;
	
	enum 'Rainbow', [ qw( red orange yellow green blue purple ) ];
	
	class_type 'HTTP::Tiny';
	
	$INC{'My/Types.pm'} = __FILE__;
};

cmp_deeply(
	\@My::Types::EXPORT,
	bag(),
	'@EXPORT',
) or diag explain( \@My::Types::EXPORT );

cmp_deeply(
	\@My::Types::EXPORT_OK,
	bag( qw/
		assert_HTTPTiny
		assert_Rainbow
		RAINBOW_RED
		RAINBOW_ORANGE
		RAINBOW_YELLOW
		RAINBOW_GREEN
		RAINBOW_BLUE
		RAINBOW_PURPLE
		is_HTTPTiny
		is_Rainbow
		to_HTTPTiny
		to_Rainbow
		HTTPTiny
		Rainbow
	/ ),
	'@EXPORT_OK',
) or diag explain( \@My::Types::EXPORT_OK );

cmp_deeply(
	\%My::Types::EXPORT_TAGS,
	{
		assert => bag( qw/
			assert_HTTPTiny
			assert_Rainbow
		/ ),
		constants => bag( qw/
			RAINBOW_RED
			RAINBOW_ORANGE
			RAINBOW_YELLOW
			RAINBOW_GREEN
			RAINBOW_BLUE
			RAINBOW_PURPLE
		/ ),
		is => bag( qw/
			is_HTTPTiny
			is_Rainbow
		/ ),
		to => bag( qw/
			to_HTTPTiny
			to_Rainbow
		/ ),
		types => bag( qw/
			HTTPTiny
			Rainbow
		/ ),
	},
	'%EXPORT_TAGS',
) or diag explain( \%My::Types::EXPORT_TAGS );

{
	my %imported;
	use My::Types { into => \%imported }, qw( -assert );
	cmp_deeply(
		\%imported,
		{
			assert_HTTPTiny => ignore(),
			assert_Rainbow => ignore(),
		},
		'qw( -assert )',
	) or diag explain ( \%imported );
}

{
	my %imported;
	use My::Types { into => \%imported }, qw( -constants );
	cmp_deeply(
		\%imported,
		{
			RAINBOW_RED    => ignore(),
			RAINBOW_ORANGE => ignore(),
			RAINBOW_YELLOW => ignore(),
			RAINBOW_GREEN  => ignore(),
			RAINBOW_BLUE   => ignore(),
			RAINBOW_PURPLE => ignore(),
		},
		'qw( -constants )',
	) or diag explain ( \%imported );
}

{
	my %imported;
	use My::Types { into => \%imported }, qw( -is );
	cmp_deeply(
		\%imported,
		{
			is_HTTPTiny => ignore(),
			is_Rainbow => ignore(),
		},
		'qw( -is )',
	) or diag explain ( \%imported );
}

{
	my %imported;
	use My::Types { into => \%imported }, qw( -to );
	cmp_deeply(
		\%imported,
		{
			to_HTTPTiny => ignore(),
			to_Rainbow => ignore(),
		},
		'qw( -to )',
	) or diag explain ( \%imported );
}

{
	my %imported;
	use My::Types { into => \%imported }, qw( -types );
	cmp_deeply(
		\%imported,
		{
			HTTPTiny => ignore(),
			Rainbow => ignore(),
		},
		'qw( -types )',
	) or diag explain ( \%imported );
}

{
	my %imported;
	use My::Types { into => \%imported }, qw( -all );
	cmp_deeply(
		\%imported,
		{
			assert_HTTPTiny => ignore(),
			assert_Rainbow => ignore(),
			RAINBOW_RED    => ignore(),
			RAINBOW_ORANGE => ignore(),
			RAINBOW_YELLOW => ignore(),
			RAINBOW_GREEN  => ignore(),
			RAINBOW_BLUE   => ignore(),
			RAINBOW_PURPLE => ignore(),
			is_HTTPTiny => ignore(),
			is_Rainbow => ignore(),
			to_HTTPTiny => ignore(),
			to_Rainbow => ignore(),
			HTTPTiny => ignore(),
			Rainbow => ignore(),
		},
		'qw( -all )',
	) or diag explain ( \%imported );
}

{
	my %imported;
	use My::Types { into => \%imported }, qw( +HTTPTiny );
	cmp_deeply(
		\%imported,
		{
			assert_HTTPTiny => ignore(),
			is_HTTPTiny => ignore(),
			to_HTTPTiny => ignore(),
			HTTPTiny => ignore(),
		},
		'qw( +HTTPTiny )',
	) or diag explain ( \%imported );
}

{
	my %imported;
	use My::Types { into => \%imported }, qw( +Rainbow );
	cmp_deeply(
		\%imported,
		{
			assert_Rainbow => ignore(),
			RAINBOW_RED    => ignore(),
			RAINBOW_ORANGE => ignore(),
			RAINBOW_YELLOW => ignore(),
			RAINBOW_GREEN  => ignore(),
			RAINBOW_BLUE   => ignore(),
			RAINBOW_PURPLE => ignore(),
			is_Rainbow => ignore(),
			to_Rainbow => ignore(),
			Rainbow => ignore(),
		},
		'qw( +Rainbow )',
	) or diag explain ( \%imported );
}

done_testing;
