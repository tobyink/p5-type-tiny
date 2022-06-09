=pod

=encoding utf-8

=head1 PURPOSE

Checks Type::Parser works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017-2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( ./lib ./t/lib ../inc ./inc );

use Test::More;
use Test::TypeTiny;
use Test::Fatal;

use Type::Parser qw( _std_eval parse extract_type );
use Types::Standard qw( -types slurpy );
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
types_equal("Tuple[]", Tuple[], "empty parameterization against parameterizble type");
types_equal("ArrayRef[]", ArrayRef, "empty parameterization against parameterizable type");
types_equal("ArrayRef[Int]", ArrayRef[Int], "parameterized type");
types_equal("Overload[15]", Overload[15], "numeric parameter (decimal integer)");
types_equal("Overload[0x0F]", Overload[15], "numeric parameter (hexadecimal integer)");
types_equal("Overload[0x0f]", Overload[15], "numeric parameter (hexadecimal integer, lowercase)");
types_equal("Overload[-0xF]", Overload[-15], "numeric parameter (hexadecimal integer, negative)");
types_equal("Overload[1.5]", Overload[1.5], "numeric parameter (float)");
types_equal("Ref['HASH']", Ref['HASH'], "string parameter (singles)");
types_equal("Ref[\"HASH\"]", Ref['HASH'], "string parameter (doubles)");
types_equal("Ref[q(HASH)]", Ref['HASH'], "string parameter (q)");
types_equal("Ref[qq(HASH)]", Ref['HASH'], "string parameter (qq)");
types_equal("StrMatch[qr{foo}]", StrMatch[qr{foo}], "regexp parameter");

# No, Overload[15] doesn't make much sense, but it's one of the few types in
# Types::Standard that accept pretty much any list of strings as parameters.

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

note "Bad expressions";
like(
	exception { _std_eval('%hello') },
	qr{^Unexpected token in primary type expression; got '%hello'},
	'weird token'
);
like(
	exception { _std_eval('Str Int') },
	qr{^Unexpected tail on type expression:  Int},
	'weird stuff 1'
);
like(
	exception { _std_eval('ArrayRef(Int)') },
	qr{^Unexpected tail on type expression: .Int.},
	'weird stuff 2'
);

note "Tail retention";
my ($ast, $remaining) = parse("ArrayRef   [DateTime::]  |HashRef[ Int|\tDateTime::]|CodeRef monkey nuts ");
is($remaining, " monkey nuts ", "remainder is ok");

($ast, $remaining) = parse("Int, Str");
is($remaining, ", Str", "comma can indicate beginning of remainder");

require Type::Registry;
my $type;
my $reg = Type::Registry->new;
$reg->add_types( -Standard );
($type, $remaining) = extract_type('ArrayRef [ Int ] yah', $reg);
types_equal($type, ArrayRef[Int], 'extract_type works');
like($remaining, qr/\A\s?yah\z/, '... and provides proper remainder too');

note "Parsing edge cases";
is_deeply(
	scalar parse('Xyzzy[Foo]'),
	{
		'type' => 'parameterized',
		'base' => {
			'type' => 'primary',
			'token' => bless( [
				'TYPE',
				'Xyzzy'
			], 'Type::Parser::Token' ),
		},
		'params' => {
			'type' => 'list',
			'list' => [
				{
					'type' => 'primary',
					'token' => bless( [
						'TYPE',
						'Foo'
					], 'Type::Parser::Token' ),
				}
			],
		},
	},
	'Xyzzy[Foo] - parameter is treated as a type constraint'
);
is_deeply(
	scalar parse('Xyzzy["Foo"]'),
	{
		'type' => 'parameterized',
		'base' => {
			'type' => 'primary',
			'token' => bless( [
				'TYPE',
				'Xyzzy'
			], 'Type::Parser::Token' ),
		},
		'params' => {
			'type' => 'list',
			'list' => [
				{
					'type' => 'primary',
					'token' => bless( [
						'QUOTELIKE',
						'"Foo"'
					], 'Type::Parser::Token' ),
				}
			],
		},
	},
	'Xyzzy["Foo"] - parameter is treated as a string'
);
is_deeply(
	scalar parse('Xyzzy[-100]'),
	{
		'type' => 'parameterized',
		'base' => {
			'type' => 'primary',
			'token' => bless( [
				'TYPE',
				'Xyzzy'
			], 'Type::Parser::Token' ),
		},
		'params' => {
			'type' => 'list',
			'list' => [
				{
					'type' => 'primary',
					'token' => bless( [
						'STRING',
						'-100'
					], 'Type::Parser::Token' ),
				}
			],
		},
	},
	'Xyzzy[-100] - parameter is treated as a string'
);
is_deeply(
	scalar parse('Xyzzy[200]'),
	{
		'type' => 'parameterized',
		'base' => {
			'type' => 'primary',
			'token' => bless( [
				'TYPE',
				'Xyzzy'
			], 'Type::Parser::Token' ),
		},
		'params' => {
			'type' => 'list',
			'list' => [
				{
					'type' => 'primary',
					'token' => bless( [
						'STRING',
						'200'
					], 'Type::Parser::Token' ),
				}
			],
		},
	},
	'Xyzzy[200] - parameter is treated as a string'
);
is_deeply(
	scalar parse('Xyzzy[+20.0]'),
	{
		'type' => 'parameterized',
		'base' => {
			'type' => 'primary',
			'token' => bless( [
				'TYPE',
				'Xyzzy'
			], 'Type::Parser::Token' ),
		},
		'params' => {
			'type' => 'list',
			'list' => [
				{
					'type' => 'primary',
					'token' => bless( [
						'STRING',
						'+20.0'
					], 'Type::Parser::Token' ),
				}
			],
		},
	},
	'Xyzzy[+20.0] - parameter is treated as a string'
);

done_testing;
