=pod

=encoding utf-8

=head1 PURPOSE

Compares the speed of the constructor in six equivalent classes built
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

=item B<Mouse>

L<Mouse> with L<Mouse> type constraints. Class is made immutable.
B<< XS is switched off using C<MOUSE_PUREPERL> environment variable. >>

=item B<Mouse_TT>

L<Mouse> with L<Type::Tiny> type constraints. Class is made immutable.
B<< XS is switched off using C<MOUSE_PUREPERL> environment variable. >>

=back

=head1 RESULTS

In all cases, L<Type::Tiny> type constraints are clearly faster
than the conventional approach:

             Rate Moo_MXTML     Mouse     Moose    Moo_TT  Mouse_TT  Moose_TT
 Moo_MXTML 2999/s        --      -32%      -52%      -56%      -68%      -69%
 Mouse     4436/s       48%        --      -29%      -34%      -52%      -54%
 Moose     6279/s      109%       42%        --       -7%      -33%      -35%
 Moo_TT    6762/s      125%       52%        8%        --      -27%      -30%
 Mouse_TT  9309/s      210%      110%       48%       38%        --       -4%
 Moose_TT  9686/s      223%      118%       54%       43%        4%        --

(Tested versions: Type::Tiny 0.005_06, Moose 2.0604, Moo 1.002000,
MooX::Types::MooseLike 0.16, and Mouse 1.11)

=head1 DEPENDENCIES

L<Moo>, L<MooX::Types::MooseLike::Base>, L<Moose>, L<Mouse>.

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

BEGIN { $ENV{MOUSE_PUREPERL} = 1 };

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
	use Types::Standard qw(HashRef ArrayRef Int);
	has attr1 => (is  => "ro", isa => ArrayRef[Int]);
	has attr2 => (is  => "ro", isa => HashRef[ArrayRef[Int]]);
	__PACKAGE__->meta->make_immutable;
}

{
	package Local::Mouse;
	use Mouse;
	has attr1 => (is  => "ro", isa => "ArrayRef[Int]");
	has attr2 => (is  => "ro", isa => "HashRef[ArrayRef[Int]]");
	__PACKAGE__->meta->make_immutable;
}

{
	package Local::Mouse_TT;
	use Mouse;
	use Types::Standard qw(HashRef ArrayRef Int);
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
	Mouse     => q{ Local::Mouse->new(%::data) },
	Moo_TT    => q{ Local::Moo_TT->new(%::data) },
	Moose_TT  => q{ Local::Moose_TT->new(%::data) },
	Mouse_TT  => q{ Local::Moose_TT->new(%::data) },
});
