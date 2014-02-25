=pod

=encoding utf-8

=head1 PURPOSE

Checks the types adopted from Moose still have a coercion which works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::Requires { Moose => '2.0600' };
use Test::TypeTiny;

my $Rounded = do {
	use Moose::Util::TypeConstraints;
	subtype 'RoundedInt', as 'Int';
	coerce 'RoundedInt', from 'Num', via { int($_) };
	find_type_constraint 'RoundedInt';
};

my $Array_of_Rounded = do {
	use Types::Standard -types;
	ArrayRef[$Rounded];
};

isa_ok(
	$Array_of_Rounded->type_parameter,
	'Type::Tiny',
	'$Array_of_Rounded->type_parameter',
);

isa_ok(
	$Array_of_Rounded->type_parameter->coercion,
	'Type::Coercion',
	'$Array_of_Rounded->type_parameter->coercion',
);

isa_ok(
	$Array_of_Rounded->type_parameter->coercion,
	'Type::Coercion::FromMoose',
	'$Array_of_Rounded->type_parameter->coercion',
);

is_deeply(
	$Array_of_Rounded->coerce([ 9.1, 1.1, 2.2, 3.3 ]),
	[ 9, 1..3 ],
	'coercion works',
);

# Making this work might prevent coercions from being inlined
# unless the coercion has been frozen.
#
TODO: {
	local $TODO = "\$Array_of_Rounded's coercion has already been compiled";
	coerce 'RoundedInt', from 'Undef', via { 0 };
	is_deeply(
		$Array_of_Rounded->coerce([ 9.1, 1.1, undef, 3.3 ]),
		[ 9, 1, 0, 3 ],
		'coercion can be altered later',
	);
};

done_testing;
