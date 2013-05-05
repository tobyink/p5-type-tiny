=pod

=encoding utf-8

=head1 PURPOSE

Compares the speed of the constructor in four equivalent classes built
using different tools:

=over

=item B<Moo_MXTML>

L<Moo> with L<MooX::Types::MooseLike::Base> types and non-L<Sub::Quote>
coderef coercions.

=item B<Moo_TT>

L<Moo> with L<Type::Tiny> types and coercions.

=item B<Moose>

L<Moose> with L<Moose> type constraints and coderef coercions. Class is made
immutable.

=item B<Moose_TT>

L<Moose> with L<Type::Tiny> type constraints and coercions. Class is made
immutable.

=back


=head1 RESULTS

For both Moose and Moo, L<Type::Tiny> type constraints are clearly faster
than the conventional approach:

               Rate Moo_MXTML    Moo_TT     Moose  Moose_TT
   Moo_MXTML 3412/s        --      -33%      -49%      -60%
   Moo_TT    5119/s       50%        --      -23%      -39%
   Moose     6636/s       94%       30%        --      -21%
   Moose_TT  8452/s      148%       65%       27%        --

(Tested versions: Type::Tiny 0.003_16, Moose 2.0604, Moo 1.002000, and
MooX::Types::MooseLike 0.16.)

=head1 DEPENDENCIES

L<Moo>, L<MooX::Types::MooseLike::Base>, L<Moose>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

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
	use Types::Standard qw(HashRef ArrayRef Int);
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
