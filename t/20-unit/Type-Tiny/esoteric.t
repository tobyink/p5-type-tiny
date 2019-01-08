=pod

=encoding utf-8

=head1 PURPOSE

Checks various undocumented Type::Tiny methods.

The fact that these are tested here should not be construed to mean tht
they are any any way a stable, supported part of the Type::Tiny API.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017-2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::Fatal;
use Test::TypeTiny;

use Type::Tiny;
use Types::Standard -types;

is_deeply(
	Int->inline_environment,
	{},
	'$type->inline_environment',
);

my $check = Int->_inline_check('$foo');
ok(
	eval("my \$foo = 42; $check") && !eval("my \$foo = 4.2; $check"),
	'$type->_inline_check',
);

ok(
	Int->_compiled_type_constraint->("42") && !Int->_compiled_type_constraint->("4.2"),
	'$type->_compiled_type_constraint',
);

like(
	exception { Any->meta },
	qr/^Not really a Moose::Meta::TypeConstraint/,
	'$type->meta',
);

ok(
	Int->compile_type_constraint->("42") && !Int->compile_type_constraint->("4.2"),
	'$type->compile_type_constraint',
);

ok(
	Int->_actually_compile_type_constraint->("42") && !Int->_actually_compile_type_constraint->("4.2"),
	'$type->_actually_compile_type_constraint',
);

is(
	Int->hand_optimized_type_constraint,
	undef,
	'$type->hand_optimized_type_constraint',
);

ok(
	!Int->has_hand_optimized_type_constraint,
	'$type->has_hand_optimized_type_constraint',
);

ok(
	(ArrayRef[Int])->__is_parameterized && !Int->__is_parameterized,
	'$type->__is_parameterized',
);

my $Int = Int->create_child_type;
$Int->_add_type_coercions(Num, q[int($_)]);
is(
	$Int->coerce(42.1),
	42,
	'$type->_add_type_coercions',
);

is(
	Int->_as_string,
	'Types::Standard::Int',
	'$type->_as_string',
);

is(
	$Int->_compiled_type_coercion->(6.2),
	6,
	'$type->_compiled_type_coercion',
);

ok(
	Int->_identity != $Int->_identity,
	'$type->_identity',
);

my $union = Int->_unite(ArrayRef);
ok(
	$union->equals( Int | ArrayRef ),
	'$type->_unite',
);

done_testing;
