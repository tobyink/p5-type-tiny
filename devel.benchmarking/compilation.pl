use strict;
use Benchmark qw(:all);

use Types::Standard qw(ArrayRef Int);

my $type = ArrayRef[Int];
our $data = [1..10];

*orig     = sub { $type->check(@_) };
*compiled = $type->compiled_check;

cmpthese(-1, {
	orig     => q[ orig($::data) ],
	compiled => q[ compiled($::data) ],
});

# compiled type check is much faster!

__END__
            Rate     orig compiled
orig       914/s       --     -97%
compiled 34796/s    3706%       --
