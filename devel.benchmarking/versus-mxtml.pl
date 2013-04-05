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

#use B::Deparse;
#print B::Deparse->new->coderef2text(Local::TT->can('new'));

__END__
        Rate MXTML    TT
MXTML 3110/s    --  -48%
TT    6032/s   94%    --

