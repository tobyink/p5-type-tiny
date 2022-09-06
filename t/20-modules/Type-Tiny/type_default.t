=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Tiny's C<type_default> attribute works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::Fatal;

use Types::Standard -types;

is(
	Any->type_default->(),
	undef,
	'Any->type_default',
);

is(
	Item->type_default->(),
	undef,
	'Item->type_default (inherited from Any)',
);

is(
	Defined->type_default,
	undef,
	'Defined->type_default (not inherited from Item)',
);

is(
	Str->type_default->(),
	'',
	'Str->type_default',
);

is(
	$_->type_default->(),
	0,
	"$_\->type_default",
) for Int, Num, StrictNum, LaxNum;

is(
	Bool->type_default->(),
	!!0,
	'Bool->type_default',
);

is(
	Undef->type_default->(),
	undef,
	'Undef->type_default',
);

is(
	Maybe->type_default->(),
	undef,
	'Maybe->type_default',
);

is(
	Maybe->of( Str )->type_default->(),
	'',
	'Maybe[Str]->type_default generated for parameterized type',
);

is_deeply(
	ArrayRef->type_default->(),
	[],
	'ArrayRef->type_default',
);

is_deeply(
	ArrayRef->of( Str )->type_default->(),
	[],
	'ArrayRef[Str]->type_default generated for parameterized type',
);

is(
	ArrayRef->of( Str, 1, 2 )->type_default,
	undef,
	'ArrayRef[Str, 1, 2]->type_default not generated',
);

is_deeply(
	HashRef->type_default->(),
	{},
	'HashRef->type_default',
);

is_deeply(
	HashRef->of( Str )->type_default->(),
	{},
	'HashRef[Str]->type_default generated for parameterized type',
);

is_deeply(
	Map->type_default->(),
	{},
	'Map->type_default',
);

is_deeply(
	Map->of( Str, Int )->type_default->(),
	{},
	'Map[Str, Int]->type_default generated for parameterized type',
);

subtest "quasi-curry" => sub {
	my @got;
	my $type = ArrayRef->create_child_type(
		name          => 'MyArrayRef',
		type_default  => sub { @got = @_; return $_ },
	);
	my $td = $type->type_default( 1 .. 5 );
	is( ref($td), 'CODE', 'quasi-curry worked' );
	is_deeply(
		$td->( bless {}, 'Local::Dummy' ),
		[ 1 .. 5 ],
		'quasi-curried arguments',
	);
	is_deeply(
		\@got,
		[ bless {}, 'Local::Dummy' ],
		'regular arguments',
	);
};

done_testing;
