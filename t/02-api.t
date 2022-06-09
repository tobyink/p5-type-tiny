=pod

=encoding utf-8

=head1 PURPOSE

Test that Type::Tiny and Type::Coercion provide a Moose/Mouse-compatible API.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

my $HAVE_MOOSE = eval {
	require Moose;
	Moose->VERSION('2.000');
	1; # return true
};

my @MOOSE_WANTS = qw(
	_actually_compile_type_constraint
	_collect_all_parents
	_compile_subtype
	_compile_type
	_compiled_type_constraint
	_default_message
	_has_compiled_type_constraint
	_inline_check
	_new
	_package_defined_in
	_set_constraint
	assert_coerce
	assert_valid
	can_be_inlined
	check
	coerce
	coercion
	compile_type_constraint
	constraint
	create_child_type
	equals
	get_message
	has_coercion
	has_message
	has_parent
	inline_environment
	inlined
	is_a_type_of
	is_subtype_of
	message
	meta
	name
	new
	parent
	parents
	validate
);

my $HAVE_MOUSE = eval { require Mouse };

my @MOUSE_WANTS = qw(
	__is_parameterized
	_add_type_coercions
	_as_string
	_compiled_type_coercion
	_compiled_type_constraint
	_identity
	_unite
	assert_valid
	check
	coerce
	compile_type_constraint
	create_child_type
	get_message
	has_coercion
	is_a_type_of
	message
	name
	new
	parameterize
	parent
	type_parameter
);

require Type::Tiny;

my $type = "Type::Tiny"->new(name => "TestType");

if ( $HAVE_MOOSE ) {
	no warnings 'once';
	*Moose::Meta::TypeConstraint::bleh_this_does_not_exist = sub { 42 };
	push @MOOSE_WANTS, 'bleh_this_does_not_exist';
}

for (@MOOSE_WANTS)
{
	SKIP: {
		skip "Moose::Meta::TypeConstraint PRIVATE API: '$_'", 1 if /^_/ && !$HAVE_MOOSE;
		ok($type->can($_), "Moose::Meta::TypeConstraint API: $type->can('$_')");
	}
}

if ( $HAVE_MOOSE ) {
	is( $type->can('bleh_this_does_not_exist')->( $type ), 42 );
	is( $type->bleh_this_does_not_exist(), 42 );
}

for (@MOUSE_WANTS)
{
	SKIP: {
		skip "Mouse::Meta::TypeConstraint PRIVATE API: '$_'", 1 if /^_/ && !$HAVE_MOUSE;
		ok($type->can($_), "Mouse::Meta::TypeConstraint API: $type->can('$_')");
	}
}

my @MOOSE_WANTS_COERCE = qw(
	_compiled_type_coercion
	_new
	add_type_coercions
	coerce
	compile_type_coercion
	has_coercion_for_type
	meta
	new
	type_coercion_map
	type_constraint
);

require Type::Coercion;

my $coerce = "Type::Coercion"->new(name => "TestCoercion");

for (@MOOSE_WANTS_COERCE)
{
	SKIP: {
		skip "Moose::Meta::TypeCoercion PRIVATE API: '$_'", 1 if /^_/ && !$HAVE_MOOSE;
		ok($coerce->can($_), "Moose::Meta::TypeCoercion API: $coerce->can('$_')");
	}
}

BAIL_OUT("Further tests rely on the Type::Tiny and Type::Coercion APIs.")
	unless "Test::Builder"->new->is_passing;

done_testing;
