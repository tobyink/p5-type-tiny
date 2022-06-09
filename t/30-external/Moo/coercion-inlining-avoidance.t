=pod

=encoding utf-8

=head1 PURPOSE

A rather complex case of defining an attribute with a type coercion in
Moo; and only then adding coercion definitions to it. Does Moo pick up
on the changes? It should.

=head1 DEPENDENCIES

Test is skipped if Moo 1.004000 is not available.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

use Test::More;
use Test::Requires { 'Moo' => '1.004000' };
use Test::Fatal;

use Types::Standard -types;

my $e;

my $type = Int->create_child_type(
	name     => 'MyInt',
	coercion => [ Num, q[int($_)] ],
);

ok(
	!$type->coercion->frozen,
	'created a type constraint without a frozen coercion',
);

ok(
	!$type->coercion->can_be_inlined,
	'... it reports that it cannot be inlined',
);

{
	package Foo;
	use Moo;
	has foo => (is => 'ro', isa => $type, coerce => $type->coercion);
}

# We need to do some quick checks before adding the coercions,
# partly because this is interesting to check, and partly because
# we need to ensure that the 
is(
	Foo->new(foo => 3.2)->foo,
	3,
	'initial use of type in a Moo constructor',
);

$e = exception { Foo->new(foo => [3..4])->foo };
like(
	$e->message,
	qr/did not pass type constraint/,
	'... and it cannot coerce from an arrayref',
);

$e = exception { Foo->new(foo => { value => 42 })->foo };
like(
	$e->message,
	qr/did not pass type constraint/,
	'... and it cannot coerce from an hashref',
);

is(
	exception {
		$type->coercion->add_type_coercions(
			ArrayRef,  q[scalar(@$_)],
			HashRef,   q[$_->{value}],
			ScalarRef, q["this is just a talisman"],
		);
	},
	undef,
	'can add coercions from ArrayRef and HashRef to the type',
);

ok(
	!$type->coercion->frozen,
	'... it is still not frozen',
);

ok(
	!$type->coercion->can_be_inlined,
	'... it reports that it still cannot be inlined',
);

is(
	Foo->new(foo => 3.2)->foo,
	3,
	'again use of type in a Moo constructor',
);

is(
	Foo->new(foo => [3..4])->foo,
	2,
	'... but can coerce from ArrayRef',
);

is(
	Foo->new(foo => { value => 42 })->foo,
	42,
	'... and can coerce from HashRef',
);

is(
	exception { $type->coercion->freeze },
	undef,
	'can freeze the coercion',
);

ok(
	$type->coercion->frozen,
	'... it reports that it is frozen',
);

ok(
	$type->coercion->can_be_inlined,
	'... it reports that it can be inlined',
);

{
	package Goo;
	use Moo;
	has foo => (is => 'ro', isa => $type, coerce => $type->coercion);
}

Goo->new;

if ( $ENV{AUTHOR_TESTING} )
{
	require B::Deparse;
	my $deparsed = B::Deparse->new->coderef2text(\&Goo::new);
	like($deparsed, qr/talisman/i, 'Moo inlining for coercions')
		or diag($deparsed);
}

done_testing;
