=pod

=encoding utf-8

=head1 PURPOSE

Checks various values against C<CycleTuple> from Types::Standard.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::TypeTiny;
use Test::Fatal qw(exception);

use Types::Standard qw( CycleTuple Num Int HashRef ArrayRef Any Optional slurpy );
use Type::Utils qw( class_type );

my $type1 = CycleTuple[
	Int->plus_coercions(Num, 'int($_)'),
	HashRef,
	ArrayRef,
];

my $type2 = CycleTuple[
	Int->where(sub{2})->plus_coercions(Num, 'int($_)'),
	HashRef,
	ArrayRef,
];

my $type3 = CycleTuple[
	Int->plus_coercions(Num->where(sub{2}), 'int($_)'),
	HashRef,
	ArrayRef,
];

my $type4 = CycleTuple[
	Int->where(sub{2})->plus_coercions(Num->where(sub{2}), 'int($_)'),
	HashRef,
	ArrayRef,
];

my $i;
for my $type ($type1, $type2, $type3, $type4)
{
	++$i;
	subtest "\$type$i" => sub {
		should_fail(undef, $type);
		should_fail({}, $type);
		should_pass([], $type);
		should_fail([{}], $type);
		should_fail([1], $type);
		should_fail([1,{}], $type);
		should_pass([1,{}, []], $type);
		should_fail([1,{}, [], undef], $type);
		should_fail([1,{}, [], 2], $type);
		should_pass([1,{}, [], 2, {}, [1]], $type);

		is_deeply(
			$type->coerce([1.1, {}, [], 2.2, {}, [3.3]]),
			[1, {}, [], 2, {}, [3.3]],
			'automagic coercion',
		);
	};
}

like(
	exception { CycleTuple[Any, Optional[Any]] },
	qr/cannot be optional/i,
	'cannot make CycleTuples with optional slots',
);

like(
	exception { CycleTuple[Any, slurpy ArrayRef] },
	qr/cannot be slurpy/i,
	'cannot make CycleTuples with slurpy slots',
);

# should probably write a test case for this.
#diag exception { $type->assert_return([1,{},[],[],[],[]]) };

done_testing;
