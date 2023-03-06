use strict;
use warnings;
use Test::More;

use Type::Tiny::Bitfield (
	Colour  => { RED => 0x01, BLUE => 0x02, GREEN => 0x04, -prefix => 'My' },
);

is( MyColour->display_name, 'Colour' );

is( MyCOLOUR_RED, 1 );

done_testing;
