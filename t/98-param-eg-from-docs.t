use strict;
use warnings;
use Test::TypeTiny;
use Test::More;

BEGIN {
	package My::Types;
	use Type::Library -base;
	use Type::Utils 'extends';
	BEGIN { extends 'Types::Standard' };	
	__PACKAGE__->add_type(
		name       => 'MultipleOf',
		parent     => Int,
		constraint_generator => sub {
			my $i = assert_Int(shift);
			return sub { $_ % $i == 0 };
		},
		inline_generator => sub {
			my $i = shift;
			return sub {
				my $varname = pop;
				return (undef, "($varname % $i == 0)");
			};
		},
		coercion_generator => sub {
			my $i = $_[2];
			require Type::Coercion;
			return Type::Coercion->new(
				type_coercion_map => [
					Num, qq{ int($i * int(\$_/$i)) }
				],
			);
		},
	);
	__PACKAGE__->make_immutable;
	$INC{'My/Types.pm'} = __FILE__;
};

use My::Types 'MultipleOf';

my $MultipleOfThree = MultipleOf->of(3);

should_pass(0, $MultipleOfThree);
should_fail(1, $MultipleOfThree);
should_fail(2, $MultipleOfThree);
should_pass(3, $MultipleOfThree);
should_fail(4, $MultipleOfThree);
should_fail(5, $MultipleOfThree);
should_pass(6, $MultipleOfThree);
should_fail(7, $MultipleOfThree);
should_fail(-1, $MultipleOfThree);
should_pass(-3, $MultipleOfThree);
should_fail(0.1, $MultipleOfThree);
should_fail([], $MultipleOfThree);
should_fail(undef, $MultipleOfThree);

subtest 'coercion' => sub {
	is($MultipleOfThree->coerce(0), 0);
	is($MultipleOfThree->coerce(1), 0);
	is($MultipleOfThree->coerce(2), 0);
	is($MultipleOfThree->coerce(3), 3);
	is($MultipleOfThree->coerce(4), 3);
	is($MultipleOfThree->coerce(5), 3);
	is($MultipleOfThree->coerce(6), 6);
	is($MultipleOfThree->coerce(7), 6);
	is($MultipleOfThree->coerce(8), 6);
	is($MultipleOfThree->coerce(8.9), 6);
};

#diag( $MultipleOfThree->inline_check('$VALUE') );

done_testing;

