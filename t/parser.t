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
use Types::Standard -types;

sub types_equal
{
	my ($a, $b) = map { ref($_) ? $_ : _std_eval($_) } @_[0, 1];
	my ($A, $B) = map { $_->inline_check('$X') } ($a, $b);
	my $msg = "$_[0] eq $_[1]";
	$msg = "$msg - $_[2]" if $_[2];
	@_ = ($A, $B, $msg);
	goto \&Test::More::is;
}

# basics
types_equal("Int", Int);
types_equal("(Int)", Int, "redundant parentheses");
types_equal("((((Int))))", Int, "many redundant parentheses");

# class types
types_equal("DateTime::", InstanceOf["DateTime"]);
types_equal("InstanceOf['DateTime']", InstanceOf["DateTime"]);
types_equal("Tied[Foo::]", Tied["Foo"]);
types_equal("Tied['Foo']", Tied["Foo"]);

# parameterization
types_equal("Int[]", Int, "empty parameterization against non-parameterizable type");
types_equal("ArrayRef[]", ArrayRef, "empty parameterization against parameterizable type");
types_equal("ArrayRef[Int]", ArrayRef[Int], "parameterized type");
types_equal("Ref['HASH']", Ref['HASH'], "string parameter (singles)");
types_equal("Ref[\"HASH\"]", Ref['HASH'], "string parameter (doubles)");
types_equal("Ref[q(HASH)]", Ref['HASH'], "string parameter (q)");
types_equal("Ref[qq(HASH)]", Ref['HASH'], "string parameter (qq)");

# unions
types_equal("Int|HashRef", Int|HashRef);
types_equal("Int|HashRef|ArrayRef", Int|HashRef|ArrayRef);
types_equal("ArrayRef[Int|HashRef]", ArrayRef[Int|HashRef], "union as a parameter");
types_equal("ArrayRef[Int|HashRef[Int]]", ArrayRef[Int|HashRef[Int]]);
types_equal("ArrayRef[HashRef[Int]|Int]", ArrayRef[HashRef([Int]) | Int]);

# intersections
types_equal("Int&Num", Int & Num);
types_equal("Int&Num&Defined", Int & Num & Defined);
types_equal("ArrayRef[Int]&Defined", (ArrayRef[Int]) & Defined);

# union + intersection
types_equal("Int&Num|ArrayRef", (Int & Num) | ArrayRef);
types_equal("(Int&Num)|ArrayRef", (Int & Num) | ArrayRef);
types_equal("Int&(Num|ArrayRef)", Int & (Num | ArrayRef));
types_equal("Int&Num|ArrayRef&Ref", (Int & Num) | (ArrayRef & Ref));

# complementary types
types_equal("~Int", ~Int);
types_equal("~ArrayRef[Int]", ArrayRef([Int])->complementary_type);
types_equal("~Int|CodeRef", (~Int)|CodeRef);
types_equal("~(Int|CodeRef)", ~(Int|CodeRef), 'precedence of "~" versus "|"');

done_testing;
