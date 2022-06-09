=pod

=encoding utf-8

=head1 PURPOSE

Checks various undocumented Type::Tiny methods.

The fact that these are tested here should not be construed to mean tht
they are any any way a stable, supported part of the Type::Tiny API.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017-2022 by Toby Inkster.

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

ok(
	(ArrayRef[Int])->has_parameterized_from && !Int->has_parameterized_from,
	'$type->has_parameterized_from',
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

like(
	Int->_stringify_no_magic,
	qr/^Type::Tiny=HASH\(0x[0-9a-f]+\)$/i,
	'$type->_stringify_no_magic',
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

{
	
	package Type::Tiny::Subclass;
	our @ISA = qw( Type::Tiny );
	sub assert_return {
		my ( $self ) = ( shift );
		++( $self->{ __PACKAGE__ . '::count' } ||= 0 );
		$self->SUPER::assert_return( @_ );
	}
	sub counter {
		my ( $self ) = ( shift );
		$self->{ __PACKAGE__ . '::count' };
	}
}

my $child = 'Type::Tiny::Subclass'->new(
	parent     => Int,
	constraint => sub { $_ % 3 },
);

ok  exception { $child->( 6 ) }, 'overridden assert_return works (failing value)';
ok !exception { $child->( 7 ) }, 'overridden assert_return works (passing value)';
is( $child->counter, 2, 'overridden assert_return is used by &{} overload' );

is_deeply(
	eval( '[' . Int->____make_key( [1..4], { quux => \"abc" }, undef ) . ']' ),
	[ Int, [1..4], { quux => \"abc" }, undef ],
	'$type->____make_key'
);

done_testing;
