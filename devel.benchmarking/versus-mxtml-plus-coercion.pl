use strict;
use warnings;
use Benchmark ':all';

{
	package Local::MXTML;
	use Moo;
	use MooX::Types::MooseLike::Base qw(HashRef ArrayRef Int is_Int);
	has attr1 => (
		is     => "ro",
		isa    => ArrayRef[Int],
		coerce => sub { is_Int($_[0]) ? [ $_[0] ] : $_[0] },
	);
	has attr2 => (
		is     => "ro",
		isa    => HashRef[ArrayRef[Int]],
	);
}

{
	package Local::TT;
	use Moo;
	use Types::Standard qw(HashRef ArrayRef Int);
	use Sub::Quote;
	my $AofI = (ArrayRef[Int])->plus_coercions(Int, '[$_]');
	has attr1 => (
		is     => "ro",
		isa    => $AofI,
		coerce => $AofI->coercion,
	);
	has attr2 => (
		is     => "ro",
		isa    => HashRef[ArrayRef[Int]],
	);
}

our %data = (
	attr1  => 4,
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
MXTML 3429/s    --  -35%
TT    5288/s   54%    --

