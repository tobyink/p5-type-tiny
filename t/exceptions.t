=pod

=encoding utf-8

=head1 PURPOSE

Tests L<Type::Exception>.

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
use Test::Fatal;

use Types::Standard qw( ArrayRef Int Ref Any Num Map );

my $v = [];
my $e = exception { Int->create_child_type->assert_valid($v) };

isa_ok($e, "Type::Exception", '$e');

is(
	$e->message,
	q{[] did not pass type constraint},
	'$e->message is as expected',
);

isa_ok($e, "Type::Exception::Assertion", '$e');

cmp_ok(
	$e->type, '==', Int,
	'$e->type is as expected',
);

is(
	$e->value,
	$v,
	'$e->value is as expected',
);

is_deeply(
	$e->explain,
	[
		'"__ANON__" is a subtype of "Int"',
		'"Int" is a subtype of "Num"',
		'"Num" is a subtype of "Str"',
		'"Str" is a subtype of "Value"',
		'[] did not pass type constraint "Value"',
		'"Value" is defined as: (defined($_) and not ref($_))',
	],
	'$e->explain is as expected',
);

is_deeply(
	(exception { (ArrayRef[Int])->([1, 2, [3]]) })->explain,
	[
		'[1,2,[3]] did not pass type constraint "ArrayRef[Int]"',
		'"ArrayRef[Int]" constrains each value in the array with "Int"',
		'"Int" is a subtype of "Num"',
		'"Num" is a subtype of "Str"',
		'"Str" is a subtype of "Value"',
		'[3] did not pass type constraint "Value" (in $_->[2])',
		'"Value" is defined as: (defined($_) and not ref($_))',
	],
	'ArrayRef[Int] deep explanation, given [1, 2, [3]]',
);

is_deeply(
	(exception { (ArrayRef[Int])->({}) })->explain,
	[
		'"ArrayRef[Int]" is a subtype of "ArrayRef"',
		'{} did not pass type constraint "ArrayRef"',
		'"ArrayRef" is defined as: (ref($_) eq \'ARRAY\')',
	],
	'ArrayRef[Int] deep explanation, given {}',
);

is_deeply(
	(exception { (Ref["ARRAY"])->({}) })->explain,
	[
		'{} did not pass type constraint "Ref[ARRAY]"',
		'"Ref[ARRAY]" is defined as: (ref($_) and Scalar::Util::reftype($_) eq q(ARRAY))',
	],
	'Ref["ARRAY"] deep explanation, given {}',
);

is_deeply(
	(exception { (Map[Int,Num])->({1=>1.1,2.2=>2.3,3.3=>3.4}) })->explain,
	[
		'{1 => "1.1","2.2" => "2.3","3.3" => "3.4"} did not pass type constraint "Map[Int,Num]"',
		'"Map[Int,Num]" constrains each key in the hash with "Int"',
		'Value "2.2" did not pass type constraint "Int" (in key $_->{"2.2"})',
		'"Int" is defined as: (defined $_ and $_ =~ /\A-?[0-9]+\z/)',
	],
	'Map[Int,Num] deep explanation, given {1=>1.1,2.2=>2.3,3.3=>3.4}',
);

my $AlwaysFail = Any->create_child_type(constraint => sub { 0 });

is_deeply(
	(exception { $AlwaysFail->(1) })->explain,
	[
		'Value "1" did not pass type constraint "__ANON__"',
		'"__ANON__" is defined as: sub { 0; }',
	],
	'$AlwaysFail explanation, given 1',
);

my $e_where = exception {
#line 1 "thisfile.plx"
package Monkey::Nuts;
"Type::Exception"->throw(message => "Test");
};

#line 130 "exceptions.t"
is_deeply(
	$e_where->context,
	{
		package => "Monkey::Nuts",
		file    => "thisfile.plx",
		line    => 2,
	},
	'$e_where->context',
);

is(
	"$e_where",
	"Test at thisfile.plx line 2.\n",
	'"$e_where"',
);

done_testing;
