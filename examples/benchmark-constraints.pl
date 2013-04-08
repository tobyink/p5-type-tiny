=pod

=encoding utf-8

=head1 PURPOSE

Compares the speed of the constructor in four equivalent classes built
using different tools:

=over

=item B<Moo_MXTML>

L<Moo> with L<MooX::Types::MooseLike::Base> types.

=item B<Moo_TT>

L<Moo> with L<Type::Tiny> types.

=item B<Moose>

L<Moose> with L<Moose> type constraints. Class is made immutable.

=item B<Moose_TT>

L<Moose> with L<Type::Tiny> type constraints. Class is made immutable.

=back

In both Moo examples, the following patch was applied, which will hopefully
make it into mainstream Moo releases soon.

L<http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=gitmo/Moo.git;a=commitdiff;h=2f425b5770149d4ed2e59da001c3be052cbd6bc1>.

=head1 RESULTS

For both Moose and Moo, L<Type::Tiny> type constraints are clearly faster
than the conventional approach:

               Rate Moo_MXTML    Moo_TT     Moose  Moose_TT
   Moo_MXTML 3140/s        --      -47%      -51%      -62%
   Moo_TT    5947/s       89%        --       -8%      -28%
   Moose     6458/s      106%        9%        --      -21%
   Moose_TT  8220/s      162%       38%       27%        --

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
