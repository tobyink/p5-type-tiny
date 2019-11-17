use strict;
use warnings;
use Test::More;
use Test::TypeTiny;

use Types::Standard qw[ Bool Enum ];

my $x = Bool | Enum [ 'start-end', 'end' ];

should_pass 1, $x;
should_pass 0, $x;
should_fail 2, $x;
should_pass 'end', $x;
should_fail 'bend', $x;
should_fail 'start', $x;
should_fail 'start-', $x;
should_fail '-end', $x;
should_pass 'start-end', $x;

done_testing;
