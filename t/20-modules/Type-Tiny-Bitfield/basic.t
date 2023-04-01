use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::TypeTiny;

use Types::Common qw( Str is_CodeRef );
use Type::Tiny::Bitfield LineStyle => {
	RED    => 1,
	BLUE   => 2,
	GREEN  => 4,
	DOTTED => 64,
};

is( LineStyle->name, 'LineStyle' );
is( LineStyle->parent->name, 'PositiveOrZeroInt' );

should_pass( $_, LineStyle ) for 0, 1, 2, 3, 4, 5, 6, 7, 64, 65, 66, 67, 68, 69, 70, 71;
should_fail( $_, LineStyle ) for 8, 9, 10, 11, 12, 13, 14, 15, 62, 63, 72;
should_fail( 'RED', LineStyle );
should_fail( -4, LineStyle );

is_deeply(
	[ sort { $a cmp $b } LineStyle->constant_names ],
	[ qw/ LINESTYLE_BLUE LINESTYLE_DOTTED LINESTYLE_GREEN LINESTYLE_RED / ],
	'LineStyle->constant_names',
);

is( LINESTYLE_RED,  1, 'LINESTYLE_RED' );
is( LINESTYLE_BLUE,  2, 'LINESTYLE_BLUE' );
is( LINESTYLE_GREEN,  4, 'LINESTYLE_GREEN' );
is( LINESTYLE_DOTTED, 64, 'LINESTYLE_DOTTED' );

is( LineStyle->RED,  1, 'LineStyle->RED' );
is( LineStyle->BLUE,  2, 'LineStyle->BLUE' );
is( LineStyle->GREEN,  4, 'LineStyle->GREEN' );
is( LineStyle->DOTTED, 64, 'LineStyle->DOTTED' );

like(
	exception { LineStyle->YELLOW },
	qr/Can't locate object method "YELLOW" via package "Type::Tiny::Bitfield"/,
	'LineStyle->YELLOW fails'
);

ok( is_CodeRef( LineStyle->can( 'RED' ) ), q{LineStyle->can( 'RED' )} );
ok( !is_CodeRef( LineStyle->can( 'YELLOW' ) ), q{!LineStyle->can( 'YELLOW' )} );
is( LineStyle->can( 'GREEN' )->(), 4, q{LineStyle->can( 'GREEN' )->()} );

ok( is_LineStyle( LINESTYLE_RED ), 'is_LineStyle( LINESTYLE_RED )' );

my $RedDottedLine = LINESTYLE_RED | LINESTYLE_DOTTED;

is( $RedDottedLine, 65 );
ok( is_LineStyle( $RedDottedLine ) );

ok( !is_LineStyle( 'RED' ) );
ok( !is_LineStyle( -4 ) );

ok(  is_LineStyle( $_ ),  "is_LineStyle($_)" ) for 0, 1, 2, 3, 4, 5, 6, 7, 64, 65, 66, 67, 68, 69, 70, 71;
ok( !is_LineStyle( $_ ), "!is_LineStyle($_)" ) for 8, 9, 10, 11, 12, 13, 14, 15, 62, 63, 72;

subtest 'Bad bitfield numbering' => sub {
	local $@;
	ok !eval q{
		use Type::Tiny::Bitfield Abcdef => {
			RED    => 1,
			BLUE   => 2,
			GREEN  => 3,
			DOTTED => 4,
		};
		1;
	};
	like $@, qr/^Not a positive power of 2/, 'error message';
};

subtest 'Bad bitfield naming' => sub {
	local $@;
	ok !eval q{
		use Type::Tiny::Bitfield Abcdef => { red => 1 };
		1;
	};
	like $@, qr/^Not an all-caps name in a bitfield/, 'error message';
};

ok( LineStyle->can_be_inlined, 'can be inlined' );
note LineStyle->inline_check( '$VALUE' );

subtest 'Coercion from string' => sub {
	ok LineStyle->has_coercion;
	ok LineStyle->coercion->has_coercion_for_type( Str );
	is( to_LineStyle('reD'), 1 );
	is( to_LineStyle('GREEN reD'), 5 );
	is( to_LineStyle('reD | grEEn'), 5 );
	is( to_LineStyle('green+blue'), 6 );
	is( to_LineStyle('linestyle_dotted'), 64 );
	is( LineStyle->from_string('reD | grEEn'), 5 );
};

subtest 'Coercion to string' => sub {
	is( LineStyle->to_string( 2 ), 'BLUE' );
	is( LineStyle->to_string( 6 ), 'BLUE|GREEN' );
	is( LineStyle->to_string( 65 ), 'RED|DOTTED' );
	is( LineStyle->to_string( [] ), undef );
	is( LineStyle->to_string( -1 ), undef );
	is( LineStyle_to_Str( 65 ), 'RED|DOTTED' );
};

done_testing;
