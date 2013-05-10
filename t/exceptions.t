=pod

=encoding utf-8

=head1 PURPOSE

Tests L<Type::Exception>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::Fatal;

use Types::Standard qw( ArrayRef Int Ref Any );

my $v = [];
my $e = exception { Int->create_child_type->assert_valid($v) };

isa_ok($e, "Type::Exception", '$e');

is(
	$e->message,
	q{[] did not pass type constraint},
	'$e->message is as expected',
);

isa_ok($e, "Type::Exception::Assertion", '$e');

cmp_ok(
	$e->type, '==', Int,
	'$e->type is as expected',
);

is(
	$e->value,
	$v,
	'$e->value is as expected',
);


is_deeply(
	$e->explain,
	[
		'__ANON__ is a subtype of Int',
		'Int is a subtype of Num',
		'Num is a subtype of Str',
		'Str is a subtype of Value',
		'[] fails type constraint Value',
		'Value is defined as: (defined($_) and not ref($_))',
	],
	'$e->explain is as expected',
);

is_deeply(
	(exception { (ArrayRef[Int])->([1, 2, [3]]) })->explain,
	[
		'[1,2,[3]] fails type constraint ArrayRef[Int]',
		'Int is a subtype of Num',
		'Num is a subtype of Str',
		'Str is a subtype of Value',
		'[3] (in $_->[2]) fails type constraint Value',
		'Value is defined as: (defined($_) and not ref($_))',
	],
	'ArrayRef[Int] deep explanation, given [1, 2, [3]]',
);

is_deeply(
	(exception { (ArrayRef[Int])->({}) })->explain,
	[
		'ArrayRef[Int] is a subtype of ArrayRef',
		'{} fails type constraint ArrayRef',
		'ArrayRef is defined as: (ref($_) eq \'ARRAY\')',
	],
	'ArrayRef[Int] deep explanation, given {}',
);

is_deeply(
	(exception { (Ref["ARRAY"])->({}) })->explain,
	[
		'{} fails type constraint Ref[ARRAY]',
		'Ref[ARRAY] is defined as: (ref($_) and Scalar::Util::reftype($_) eq q(ARRAY))',
	],
	'Ref["ARRAY"] deep explanation, given {}',
);

my $AlwaysFail = Any->create_child_type(constraint => sub { 0 });

is_deeply(
	(exception { $AlwaysFail->(1) })->explain,
	[
		'Value "1" fails type constraint __ANON__',
		'__ANON__ is defined as: sub { 0; }',
	],
	'$AlwaysFail explanation, given 1',
);

done_testing;
