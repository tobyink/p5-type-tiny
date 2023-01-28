use strict;
use warnings;
use Test::More;

use Type::Tiny::Bitfield LineStyle => {
	RED    => 1,
	BLUE   => 2,
	GREEN  => 4,
	DOTTED => 64,
};

is ( LINESTYLE_RED,  1, 'LINESTYLE_RED' );
is ( LINESTYLE_BLUE,  2, 'LINESTYLE_BLUE' );
is ( LINESTYLE_GREEN,  4, 'LINESTYLE_GREEN' );
is ( LINESTYLE_DOTTED, 64, 'LINESTYLE_DOTTED' );

is ( LineStyle->RED,  1, 'LineStyle->RED' );
is ( LineStyle->BLUE,  2, 'LineStyle->BLUE' );
is ( LineStyle->GREEN,  4, 'LineStyle->GREEN' );
is ( LineStyle->DOTTED, 64, 'LineStyle->DOTTED' );

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

done_testing;
