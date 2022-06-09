=pod

=encoding utf-8

=head1 PURPOSE

Checks that all this Type[Param] syntactic sugar works. In particular, the
following three type constraints are expected to be equivalent to each other:

   use Types::Standard qw( ArrayRef Int Num Str );
   use Type::Utils qw( union intersection );
   
   my $type1 = ArrayRef[Int]
      | ArrayRef[Num & ~Int]
      | ArrayRef[Str & ~Num];
   
   my $type2 = union [
      ArrayRef[Int],
      ArrayRef[Num & ~Int],
      ArrayRef[Str & ~Num],
   ];
   
   my $type3 = union([
      ArrayRef->parameterize(Int),
      ArrayRef->parameterize(
         intersection([
            Num,
            Int->complementary_type,
         ]),
      ),
      ArrayRef->parameterize(
         intersection([
            Str,
            Num->complementary_type,
         ]),
      ),
   ]);


=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( . ./t ../inc ./inc );

use Test::More;

use Types::Standard qw( ArrayRef Int Num Str );
use Type::Utils qw( union intersection );

my $type1 = ArrayRef[Int] | ArrayRef[Num & ~Int] | ArrayRef[Str & ~Num];

my $type2 = union [
	ArrayRef[Int],
	ArrayRef[Num & ~Int],
	ArrayRef[Str & ~Num],
];

my $type3 = union([
	ArrayRef->parameterize(Int),
	ArrayRef->parameterize(
		intersection([
			Num,
			Int->complementary_type,
		]),
	),
	ArrayRef->parameterize(
		intersection([
			Str,
			Num->complementary_type,
		]),
	),
]);

ok($type1==$type2, '$type1==$type2');
ok($type1==$type3, '$type1==$type3');
ok($type2==$type3, '$type2==$type3');

done_testing;
