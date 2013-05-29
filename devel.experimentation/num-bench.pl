use strict;
use warnings;
use Benchmark qw(:all);

use Types::Standard qw( Num LaxNum StrictNum );
use MooseX::Types::Moose Num => { -as => "MXTNum" };

our @numbers = qw(
	42
	3.14159
	2.99792458e8
	-89.2
	0
	.1
	-.2
	666
	9
	10
);

cmpthese(-1, {
	Num       => q{ ::Num->assert_valid($_)       for @::numbers }, # alias for LaxNum
	LaxNum    => q{ ::LaxNum->assert_valid($_)    for @::numbers }, # uses looks_like_number
	StrictNum => q{ ::StrictNum->assert_valid($_) for @::numbers }, # uses regexp
	MXTNum    => q{ ::MXTNum->assert_valid($_)    for @::numbers }, # uses looks_like_number
});

__END__
             Rate    MXTNum StrictNum    LaxNum       Num
MXTNum      305/s        --      -95%      -97%      -97%
StrictNum  5799/s     1801%        --      -43%      -43%
LaxNum    10239/s     3257%       77%        --       -0%
Num       10240/s     3257%       77%        0%        --
