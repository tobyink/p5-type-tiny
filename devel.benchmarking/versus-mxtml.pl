use strict;
use warnings;
use Benchmark ':all';

{
	package Local::MXTML;
	use Moo;
	use MooX::Types::MooseLike::Base qw(HashRef ArrayRef Int);
	has attr1 => (is  => "ro", isa => ArrayRef[Int]);
	has attr2 => (is  => "ro", isa => HashRef[ArrayRef[Int]]);
}

{
	package Local::TT;
	use Moo;
	use Types::Standard qw(HashRef ArrayRef Int);
	has attr1 => (is  => "ro", isa => ArrayRef[Int]);
	has attr2 => (is  => "ro", isa => HashRef[ArrayRef[Int]]);
}

our %data = (
	attr1  => [1..10],
	attr2  => {
		one   => [0 .. 1],
		two   => [0 .. 2],
		three => [0 .. 3],
	},
);

cmpthese(-1, {
	MXTML => q{ Local::MXTML->new(%::data) },
	TT    => q{ Local::TT->new(%::data) },
});

__END__
        Rate MXTML    TT
MXTML 3100/s    --  -35%
TT    4799/s   55%    --
