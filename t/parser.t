=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Parser works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::TypeTiny;

use Type::Parser qw(_std_eval);
use Types::Standard qw(-types slurpy);
use Type::Utils;

sub types_equal
{
	my ($a, $b) = map { ref($_) ? $_ : _std_eval($_) } @_[0, 1];
	my ($A, $B) = map { $_->inline_check('$X') } ($a, $b);
	my $msg = "$_[0] eq $_[1]";
	$msg = "$msg - $_[2]" if $_[2];
	@_ = ($A, $B, $msg);
	goto \&Test::More::is;
}

note "Basics";
types_equal("Int", Int);
types_equal("(Int)", Int, "redundant parentheses");
types_equal("((((Int))))", Int, "many redundant parentheses");

note "Class types";
types_equal("DateTime::", InstanceOf["DateTime"]);
types_equal("InstanceOf['DateTime']", InstanceOf["DateTime"]);
types_equal("Tied[Foo::]", Tied["Foo"]);
types_equal("Tied['Foo']", Tied["Foo"]);

note "Parameterization";
types_equal("Int[]", Int, "empty parameterization against non-parameterizable type");
types_equal("ArrayRef[]", ArrayRef, "empty parameterization against parameterizable type");
types_equal("ArrayRef[Int]", ArrayRef[Int], "parameterized type");
types_equal("Ref['HASH']", Ref['HASH'], "string parameter (singles)");
types_equal("Ref[\"HASH\"]", Ref['HASH'], "string parameter (doubles)");
types_equal("Ref[q(HASH)]", Ref['HASH'], "string parameter (q)");
types_equal("Ref[qq(HASH)]", Ref['HASH'], "string parameter (qq)");
types_equal("StrMatch[qr{foo}]", StrMatch[qr{foo}], "regexp parameter");

note "Unions";
types_equal("Int|HashRef", Int|HashRef);
types_equal("Int|HashRef|ArrayRef", Int|HashRef|ArrayRef);
types_equal("ArrayRef[Int|HashRef]", ArrayRef[Int|HashRef], "union as a parameter");
types_equal("ArrayRef[Int|HashRef[Int]]", ArrayRef[Int|HashRef[Int]]);
types_equal("ArrayRef[HashRef[Int]|Int]", ArrayRef[HashRef([Int]) | Int]);

note "Intersections";
types_equal("Int&Num", Int & Num);
types_equal("Int&Num&Defined", Int & Num & Defined);
types_equal("ArrayRef[Int]&Defined", (ArrayRef[Int]) & Defined);

note "Union + Intersection";
types_equal("Int&Num|ArrayRef", (Int & Num) | ArrayRef);
types_equal("(Int&Num)|ArrayRef", (Int & Num) | ArrayRef);
types_equal("Int&(Num|ArrayRef)", Int & (Num | ArrayRef));
types_equal("Int&Num|ArrayRef&Ref", intersection([Int, Num]) | intersection([ArrayRef, Ref]));

note "Complementary types";
types_equal("~Int", ~Int);
types_equal("~ArrayRef[Int]", ArrayRef([Int])->complementary_type);
types_equal("~Int|CodeRef", (~Int)|CodeRef);
types_equal("~(Int|CodeRef)", ~(Int|CodeRef), 'precedence of "~" versus "|"');

note "Comma";
types_equal("Map[Num,Int]", Map[Num,Int]);
types_equal("Map[Int,Num]", Map[Int,Num]);
types_equal("Map[Int,Int|ArrayRef[Int]]", Map[Int,Int|ArrayRef[Int]]);
types_equal("Map[Int,ArrayRef[Int]|Int]", Map[Int,ArrayRef([Int])|Int]);
types_equal("Dict[foo=>Int,bar=>Num]", Dict[foo=>Int,bar=>Num]);
types_equal("Dict['foo'=>Int,'bar'=>Num]", Dict[foo=>Int,bar=>Num]);
types_equal("Dict['foo',Int,'bar',Num]", Dict[foo=>Int,bar=>Num]);

note "Slurpy";
types_equal("Dict[slurpy=>Int,bar=>Num]", Dict[slurpy=>Int,bar=>Num]);
types_equal("Tuple[Str, Int, slurpy ArrayRef[Int]]", Tuple[Str, Int, slurpy ArrayRef[Int]]);
types_equal("Tuple[Str, Int, slurpy(ArrayRef[Int])]", Tuple[Str, Int, slurpy ArrayRef[Int]]);

note "Complexity";
types_equal(
	"ArrayRef[DateTime::]|HashRef[Int|DateTime::]|CodeRef",
	ArrayRef([InstanceOf["DateTime"]]) | HashRef([Int|InstanceOf["DateTime"]]) | CodeRef
);
types_equal(
	"ArrayRef   [DateTime::]  |HashRef[ Int|\tDateTime::]|CodeRef ",
	ArrayRef([InstanceOf["DateTime"]]) | HashRef([Int|InstanceOf["DateTime"]]) | CodeRef,
	"gratuitous whitespace",
);

done_testing;
