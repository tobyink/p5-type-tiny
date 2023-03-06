use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::TypeTiny;

use Types::Standard qw( ArrayRef );
use Type::Tiny::Bitfield (
	Colour  => { RED => 0x01, BLUE => 0x02, GREEN => 0x04 },
	Style   => { DOTTED => 0x08, ZIGZAG => 0x10, BLINK => 0x20 },
);

my $Combined = Colour + Style;

ok( $Combined->isa('Type::Tiny::Bitfield'), "$Combined isa Type::Tiny::Bitfield" );
is( $Combined->display_name, 'Colour+Style', "$Combined display_name" );
ok( $Combined->is_anon, "$Combined is_anon" );

should_pass( $_, $Combined ) for 0 .. 0x3F;
should_fail( $_, $Combined ) for 0x40, 'BLEH', [], -1, undef, ArrayRef;

is( $Combined->coerce( 'RED|GREEN|ZIGZAG' ), 21, 'coerce' );

like(
	exception {
		my $x = Colour + ArrayRef;
	},
	qr/Bad overloaded operation/,
	'Exception when trying to add Bitfield type and non-Bitfield type',
);

like(
	exception {
		my $x = ArrayRef() + Colour;
	},
	qr/Bad overloaded operation/,
	'Exception when trying to add non-Bitfield type and Bitfield type',
);

like(
	exception {
		my $x = Colour + [];
	},
	qr/Bad overloaded operation/,
	'Exception when trying to add Bitfield type and non-type',
);

like(
	exception {
		my $x = [] + Colour;
	},
	qr/Bad overloaded operation/,
	'Exception when trying to add non-type and Bitfield type',
);

like(
	exception {
		my $x = Colour + Type::Tiny::Bitfield->new(
			name   => 'Shape',
			values => { CIRCLE => 0x40, BLUE => 0x80 },
		);
	},
	qr/Conflicting value: BLUE/,
	'Exception when trying to combine conflicting Bitfield types',
);

my $zzz = 0;
sub combine_types_with_coercions {
	my ( $x, $y ) = map {
		my $coercion = $_;
		++$zzz;
		Type::Tiny::Bitfield->new(
			values   => { "ZZZ$zzz" => 2 ** $zzz },
			coercion => $coercion,
		);
	} @_;
	return $x + $y;
}

subtest 'Combining Bitfield types with and without coercions works' => sub {
	ok( ! combine_types_with_coercions( undef, undef )->has_coercion );
	ok(   combine_types_with_coercions( undef, 1 )->has_coercion );
	ok(   combine_types_with_coercions( 1, undef )->has_coercion );
	ok(   combine_types_with_coercions( 1, 1 )->has_coercion );
};

done_testing;
