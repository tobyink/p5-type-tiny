=pod

=encoding utf-8

=head1 PURPOSE

Checks crazy Type::Coercion::FromMoose errors.

=head1 DEPENDENCIES

Moose 2.0000; otherwise skipped.

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
use Test::Requires { Moose => '2.0000' };
use Test::Fatal;

use Types::Standard -types;
use Types::TypeTiny qw( to_TypeTiny );
use Scalar::Util qw(refaddr);

my $orig = do {
	use Moose::Util::TypeConstraints;
	subtype 'RoundedInt', as 'Int';
	coerce 'RoundedInt', from 'Num', via { int($_) };
	find_type_constraint 'RoundedInt';
};

my $type = to_TypeTiny($orig);

is(
	refaddr($type->coercion->moose_coercion),
	refaddr($orig->coercion),
);

is(
	refaddr($type->moose_type->coercion),
	refaddr($orig->coercion),
);

TODO: {
	local $TODO = "Adding coercions to Type::Coercion::FromMoose not currently supported";
	
	is(
		exception { $type->coercion->add_type_coercions(Any, sub {666}) },
		undef,
		'no exception adding coercions to a Moose-imported type constraint',
	);
	
	is( $type->coerce([]), 666, '... and the coercion works' );
};

# Fake a T:C:FromMoose where the Type::Tiny object has been reaped...
require Type::Coercion::FromMoose;
my $dummy = Type::Coercion::FromMoose->new;
like (
	exception { $dummy->moose_coercion },
	qr/^The type constraint attached to this coercion has been garbage collected... PANIC/,
);

done_testing;
