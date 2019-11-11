use strict;
use warnings;
use Test::More;
use Test::Requires 'Test::Memory::Cycle';
use Test::Memory::Cycle;
use Types::Standard qw(Bool);

memory_cycle_ok(Bool, 'Bool has no cycles');

done_testing;
