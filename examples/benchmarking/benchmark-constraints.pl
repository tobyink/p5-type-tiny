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

Each tool is used to define a class like the following:

   {
      package Local::Class;
      use Whatever::Tool;
      use Types::Standard qw(HashRef ArrayRef Int);
      has attr1 => (is  => "ro", isa => ArrayRef[Int]);
      has attr2 => (is  => "ro", isa => HashRef[ArrayRef[Int]]);
   }

Then we benchmark the following object instantiation:

   Local::Class->new(
      attr1  => [1..10],
      attr2  => {
         one   => [0 .. 1],
         two   => [0 .. 2],
         three => [0 .. 3],
      },
   );

=head1 RESULTS

In all cases, L<Type::Tiny> type constraints are clearly faster
than the conventional approach.

B<< With Type::Tiny::XS: >>

              Rate Moo_MXTML     Mouse     Moose    Moo_TT  Moose_TT  Mouse_TT
 Moo_MXTML  2428/s        --      -35%      -57%      -82%      -90%      -91%
 Mouse      3759/s       55%        --      -33%      -72%      -85%      -86%
 Moose      5607/s      131%       49%        --      -58%      -78%      -79%
 Moo_TT    13274/s      447%      253%      137%        --      -48%      -51%
 Moose_TT  25358/s      945%      575%      352%       91%        --       -7%
 Mouse_TT  27306/s     1025%      626%      387%      106%        8%        --

B<< Without Type::Tiny::XS: >>

             Rate Moo_MXTML     Mouse    Moo_TT     Moose  Moose_TT  Mouse_TT
 Moo_MXTML 2610/s        --      -31%      -56%      -56%      -67%      -67%
 Mouse     3759/s       44%        --      -36%      -37%      -52%      -52%
 Moo_TT    5894/s      126%       57%        --       -1%      -24%      -25%
 Moose     5925/s      127%       58%        1%        --      -24%      -25%
 Moose_TT  7802/s      199%      108%       32%       32%        --       -1%
 Mouse_TT  7876/s      202%      110%       34%       33%        1%        --

(Tested versions: Type::Tiny 0.045_03, Type::Tiny::XS 0.004, Moose 2.1207,
Moo 1.005000, MooX::Types::MooseLike 0.25, and Mouse 2.3.0)

=head1 DEPENDENCIES

To run this script, you will need:

L<Type::Tiny::XS>,
L<Moo>, L<MooX::Types::MooseLike::Base>, L<Moose>, L<Mouse>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

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
	Mouse_TT  => q{ Local::Mouse_TT->new(%::data) },
});
