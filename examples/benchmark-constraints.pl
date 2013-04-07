use strict;
use warnings;
use Benchmark ':all';

{
	package Local::Moo_MXTML;
	use Moo;
	use MooX::Types::MooseLike::Base qw(HashRef ArrayRef Int);
	has attr1 => (is  => "ro", isa => ArrayRef[Int]);
	has attr2 => (is  => "ro", isa => HashRef[ArrayRef[Int]]);
}

{
	package Local::Moo_TT;
	use Moo;
	use Types::Standard qw(HashRef ArrayRef Int);
	has attr1 => (is  => "ro", isa => ArrayRef[Int]);
	has attr2 => (is  => "ro", isa => HashRef[ArrayRef[Int]]);
}

{
	package Local::Moose;
	use Moose;
	has attr1 => (is  => "ro", isa => "ArrayRef[Int]");
	has attr2 => (is  => "ro", isa => "HashRef[ArrayRef[Int]]");
	__PACKAGE__->meta->make_immutable;
}

{
	package Local::Moose_TT;
	use Moose;
	use Types::Standard -moose, qw(HashRef ArrayRef Int);
	has attr1 => (is  => "ro", isa => ArrayRef[Int]);
	has attr2 => (is  => "ro", isa => HashRef[ArrayRef[Int]]);
	__PACKAGE__->meta->make_immutable;
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
	Moo_MXTML => q{ Local::Moo_MXTML->new(%::data) },
	Moose     => q{ Local::Moose->new(%::data) },
	Moo_TT    => q{ Local::Moo_TT->new(%::data) },
	Moose_TT  => q{ Local::Moose_TT->new(%::data) },
});

#use B::Deparse;
#print B::Deparse->new->coderef2text(Local::TT->can('new'));

__END__
            Rate Moo_MXTML    Moo_TT     Moose  Moose_TT
Moo_MXTML 3140/s        --      -47%      -51%      -62%
Moo_TT    5947/s       89%        --       -8%      -28%
Moose     6458/s      106%        9%        --      -21%
Moose_TT  8220/s      162%       38%       27%        --
