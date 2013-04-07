use strict;
use warnings;
use Benchmark ':all';

{
	package Local::Moo_MXTML;
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
	package Local::Moo_TT;
	use Moo;
	use Types::Standard qw(HashRef ArrayRef Int);
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

{
	package Local::Moose;
	use Moose;
	use Moose::Util::TypeConstraints qw(subtype as coerce from via);
	subtype "AofI", as "ArrayRef[Int]";
	coerce "AofI", from "Int", via { [$_] };
	has attr1 => (
		is     => "ro",
		isa    => "AofI",
		coerce => 1,
	);
	has attr2 => (
		is     => "ro",
		isa    => "HashRef[ArrayRef[Int]]",
	);
	__PACKAGE__->meta->make_immutable;
}

{
	package Local::Moose_TT;
	use Moose;
	use Types::Standard -moose, qw(HashRef ArrayRef Int);
	use Sub::Quote;
	my $AofI = (ArrayRef[Int])->plus_coercions(Int, '[$_]');
	has attr1 => (
		is     => "ro",
		isa    => $AofI,
		coerce => 1,
	);
	has attr2 => (
		is     => "ro",
		isa    => HashRef[ArrayRef[Int]],
	);
	__PACKAGE__->meta->make_immutable;
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
	Moo_MXTML => q{ Local::Moo_MXTML->new(%::data) },
	Moo_TT    => q{ Local::Moo_TT->new(%::data) },
	Moose_TT  => q{ Local::Moose_TT->new(%::data) },
	Moose     => q{ Local::Moose->new(%::data) },
});

#use B::Deparse;
#print B::Deparse->new->coderef2text(Local::TT->can('new'));

__END__
            Rate Moo_MXTML    Moo_TT     Moose  Moose_TT
Moo_MXTML 3459/s        --      -34%      -44%      -56%
Moo_TT    5239/s       51%        --      -16%      -33%
Moose     6207/s       79%       18%        --      -21%
Moose_TT  7859/s      127%       50%       27%        --