=pod

=encoding utf-8

=head1 PURPOSE

Tests L<Error::TypeTiny::Assertion>.

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

local $Error::TypeTiny::LastError;

use Test::More;
use Test::Fatal;

use Scalar::Util qw(refaddr);
use Types::Standard slurpy => -types;

require Error::TypeTiny::Assertion;

my $tmp = Error::TypeTiny::Assertion->new(value => 1.1, type => Int, varname => '$bob');
is($tmp->message, "Value \"1.1\" did not pass type constraint \"Int\" (in \$bob)", "autogeneration of \$e->message");

my $supernum = Types::Standard::STRICTNUM ? "StrictNum" : "LaxNum";

my $v = [];
my $e = exception { Int->create_child_type->assert_valid($v) };

isa_ok($e, "Error::TypeTiny", '$e');

is(refaddr($e), refaddr($Error::TypeTiny::LastError), '$Error::TypeTiny::LastError');

is(
	$e->message,
	q{Reference [] did not pass type constraint},
	'$e->message is as expected',
);

isa_ok($e, "Error::TypeTiny::Assertion", '$e');

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
		'"Num" is a subtype of "'.$supernum.'"',
		'"'.$supernum.'" is a subtype of "Str"',
		'"Str" is a subtype of "Value"',
		'Reference [] did not pass type constraint "Value"',
		'"Value" is defined as: (defined($_) and not ref($_))',
	],
	'$e->explain is as expected',
);

is_deeply(
	(exception { (ArrayRef[Int])->([1, 2, [3]]) })->explain,
	[
		'Reference [1,2,[3]] did not pass type constraint "ArrayRef[Int]"',
		'"ArrayRef[Int]" constrains each value in the array with "Int"',
		'"Int" is a subtype of "Num"',
		'"Num" is a subtype of "'.$supernum.'"',
		'"'.$supernum.'" is a subtype of "Str"',
		'"Str" is a subtype of "Value"',
		'Reference [3] did not pass type constraint "Value" (in $_->[2])',
		'"Value" is defined as: (defined($_) and not ref($_))',
	],
	'ArrayRef[Int] deep explanation, given [1, 2, [3]]',
);

is_deeply(
	[ @{ (exception { (ArrayRef[Int])->({}) })->explain }[0..1] ],
	[
		'"ArrayRef[Int]" is a subtype of "ArrayRef"',
		'Reference {} did not pass type constraint "ArrayRef"',
#		'"ArrayRef" is defined as: (ref($_) eq \'ARRAY\')',
	],
	'ArrayRef[Int] deep explanation, given {}',
);

is_deeply(
	(exception { (Ref["ARRAY"])->({}) })->explain,
	[
		'Reference {} did not pass type constraint "Ref[ARRAY]"',
		'"Ref[ARRAY]" constrains reftype($_) to be equal to "ARRAY"',
		'reftype($_) is "HASH"',
	],
	'Ref["ARRAY"] deep explanation, given {}',
);

is_deeply(
	(exception { (HashRef[Maybe[Int]])->({a => undef, b => 42, c => []}) })->explain,
	[
		'Reference {"a" => undef,"b" => 42,"c" => []} did not pass type constraint "HashRef[Maybe[Int]]"',
		'"HashRef[Maybe[Int]]" constrains each value in the hash with "Maybe[Int]"',
		'Reference [] did not pass type constraint "Maybe[Int]" (in $_->{"c"})',
		'Reference [] is defined',
		'"Maybe[Int]" constrains the value with "Int" if it is defined',
		'"Int" is a subtype of "Num"',
		'"Num" is a subtype of "'.$supernum.'"',
		'"'.$supernum.'" is a subtype of "Str"',
		'"Str" is a subtype of "Value"',
		'Reference [] did not pass type constraint "Value" (in $_->{"c"})',
		'"Value" is defined as: (defined($_) and not ref($_))',
	],
	'HashRef[Maybe[Int]] deep explanation, given {a => undef, b => 42, c => []}',
);

my $dict = Dict[a => Int, b => Optional[ArrayRef[Str]]];

is_deeply(
	(exception { $dict->({a => 1, c => 1}) })->explain,
	[
		'Reference {"a" => 1,"c" => 1} did not pass type constraint "Dict[a=>Int,b=>Optional[ArrayRef[Str]]]"',
		'"Dict[a=>Int,b=>Optional[ArrayRef[Str]]]" does not allow key "c" to appear in hash',
	],
	'$dict deep explanation, given {a => 1, c => 1}',
);

is_deeply(
	(exception { $dict->({b => 1}) })->explain,
	[
		'Reference {"b" => 1} did not pass type constraint "Dict[a=>Int,b=>Optional[ArrayRef[Str]]]"',
		'"Dict[a=>Int,b=>Optional[ArrayRef[Str]]]" requires key "a" to appear in hash',
	],
	'$dict deep explanation, given {b => 1}',
);

is_deeply(
	(exception { $dict->({a => 1, b => 2}) })->explain,
	[
		'Reference {"a" => 1,"b" => 2} did not pass type constraint "Dict[a=>Int,b=>Optional[ArrayRef[Str]]]"',
		'"Dict[a=>Int,b=>Optional[ArrayRef[Str]]]" constrains value at key "b" of hash with "Optional[ArrayRef[Str]]"',
		'Value "2" did not pass type constraint "Optional[ArrayRef[Str]]" (in $_->{"b"})',
		'$_->{"b"} exists',
		'"Optional[ArrayRef[Str]]" constrains $_->{"b"} with "ArrayRef[Str]" if it exists',
		'"ArrayRef[Str]" is a subtype of "ArrayRef"',
		'"ArrayRef" is a subtype of "Ref"',
		'Value "2" did not pass type constraint "Ref" (in $_->{"b"})',
		'"Ref" is defined as: (!!ref($_))',
	],
	'$dict deep explanation, given {a => 1, b => 2}',
);

TODO: {
	no warnings 'numeric'; require Data::Dumper;
	local $TODO =
		(Data::Dumper->VERSION > 2.145) ? "Data::Dumper output changed after 2.145" :
		(Data::Dumper->VERSION < 2.121) ? "Data::Dumper too old" :
		undef;
	
	is_deeply(
		(exception { (Map[Int,Num])->({1=>1.1,2.2=>2.3,3.3=>3.4}) })->explain,
		[
			'Reference {1 => "1.1","2.2" => "2.3","3.3" => "3.4"} did not pass type constraint "Map[Int,Num]"',
			'"Map[Int,Num]" constrains each key in the hash with "Int"',
			'Value "2.2" did not pass type constraint "Int" (in key $_->{"2.2"})',
			'"Int" is defined as: (do { my $tmp = $_; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ })',
		],
		'Map[Int,Num] deep explanation, given {1=>1.1,2.2=>2.3,3.3=>3.4}',
	);
}

TODO: {
	no warnings 'numeric'; require Data::Dumper;
	local $TODO =
		(Data::Dumper->VERSION < 2.121) ? "Data::Dumper too old" :
		undef;
	
	my $Ext   = (StrMatch[qr/^x_/])->create_child_type(name => 'Ext');
	my $dict2 = Dict[foo => ArrayRef, slurpy Map[$Ext, Int]];
	ok(
		$dict2->({ foo => [], x_bar => 1, x_baz => 2 }),
		"$dict2 works ok it seems",
	);

### TODO
#
#	my $e = exception { $dict2->({foo => [], x_bar => 1, x_baz => []}) };
#	is_deeply(
#		$e->explain,
#		[
#			'Reference {"foo" => [],"x_bar" => 1,"x_baz" => []} did not pass type constraint "Dict[foo=>ArrayRef,Slurpy[Map[Ext,Int]]]"',
#			'"Dict[foo=>ArrayRef,Slurpy[Map[Ext,Int]]]" requires the hashref of additional key/value pairs to conform to "Map[Ext,Int]"',
#			'Reference {"x_bar" => 1,"x_baz" => []} did not pass type constraint "Map[Ext,Int]" (in $slurpy)',
#			'"Map[Ext,Int]" constrains each value in the hash with "Int"',
#			'"Int" is a subtype of "Num"',
#			'"Num" is a subtype of "'.$supernum.'"',
#			'"'.$supernum.'" is a subtype of "Str"',
#			'"Str" is a subtype of "Value"',
#			'Reference [] did not pass type constraint "Value" (in $slurpy->{"x_baz"})',
#			'"Value" is defined as: (defined($_) and not ref($_))'
#		],
#		"$dict2 explanation, given {foo => [], x_bar => 1, x_baz => []}",
#	) or diag explain($e->explain);
}

my $AlwaysFail = Any->create_child_type(constraint => sub { 0 });

is_deeply(
	(exception { $AlwaysFail->(1) })->explain,
	[
		'Value "1" did not pass type constraint',
		'"__ANON__" is defined as: sub { 0; }',
	],
	'$AlwaysFail explanation, given 1',
);

my $TupleOf1 = Tuple[ Int ];

is_deeply(
	(exception { $TupleOf1->([1,2]) })->explain,
	[
		'Reference [1,2] did not pass type constraint "Tuple[Int]"',
		'"Tuple[Int]" expects at most 1 values in the array',
		'2 values found; too many',
	],
	'$TupleOf1 explanation, given [1,2]',
);

my $CTuple = CycleTuple[ Int, ArrayRef ];

is_deeply(
	(exception { $CTuple->([1,"Foo"]) })->explain,
	[
		'Reference [1,"Foo"] did not pass type constraint "CycleTuple[Int,ArrayRef]"',
		'"CycleTuple[Int,ArrayRef]" constrains value at index 1 of array with "ArrayRef"',
		'"ArrayRef" is a subtype of "Ref"',
		'Value "Foo" did not pass type constraint "Ref" (in $_->[1])',
		'"Ref" is defined as: (!!ref($_))',
	],
	'$CTuple explanation, given [1,"Foo"]',
);

TODO: {
	no warnings 'numeric'; require Data::Dumper;
	local $TODO =
		(Data::Dumper->VERSION < 2.121) ? "Data::Dumper too old" :
		undef;
		
	my $SlurpyThing = Tuple[ Num, slurpy Map[Str, ArrayRef] ];
	
	is_deeply(
		(exception { $SlurpyThing->(1) })->explain,
		[
			'"Tuple[Num,Slurpy[Map[Str,ArrayRef]]]" is a subtype of "Tuple"',
			'"Tuple" is a subtype of "ArrayRef"',
			'"ArrayRef" is a subtype of "Ref"',
			'Value "1" did not pass type constraint "Ref"',
			'"Ref" is defined as: (!!ref($_))',
		],
		'$SlurpyThing explanation, given 1',
	);
	
	is_deeply(
		(exception { $SlurpyThing->([[]]) })->explain,
		[
			'Reference [[]] did not pass type constraint "Tuple[Num,Slurpy[Map[Str,ArrayRef]]]"',
			'"Tuple[Num,Slurpy[Map[Str,ArrayRef]]]" constrains value at index 0 of array with "Num"',
			'"Num" is a subtype of "'.$supernum.'"',
			'"'.$supernum.'" is a subtype of "Str"',
			'"Str" is a subtype of "Value"',
			'Reference [] did not pass type constraint "Value" (in $_->[0])',
			'"Value" is defined as: (defined($_) and not ref($_))',
		],
		'$SlurpyThing explanation, given [[]]',
	);
	
	is_deeply(
		(exception { $SlurpyThing->([1.1, yeah => "Hello"]) })->explain,
		[
			'Reference ["1.1","yeah","Hello"] did not pass type constraint "Tuple[Num,Slurpy[Map[Str,ArrayRef]]]"',
			'Array elements from index 1 are slurped into a hashref which is constrained with "Map[Str,ArrayRef]"',
			'Reference {"yeah" => "Hello"} did not pass type constraint "Map[Str,ArrayRef]" (in $SLURPY)',
			'"Map[Str,ArrayRef]" constrains each value in the hash with "ArrayRef"',
			'"ArrayRef" is a subtype of "Ref"',
			'Value "Hello" did not pass type constraint "Ref" (in $SLURPY->{"yeah"})',
			'"Ref" is defined as: (!!ref($_))',
		],
		'$SlurpyThing explanation, given [1.1, yeah => "Hello"]',
	);
}

my $UndefRef = ScalarRef[Undef];

is_deeply(
	(exception { $UndefRef->(do { my $x = "bar"; \$x }) })->explain,
	[
		'Reference \\"bar" did not pass type constraint "ScalarRef[Undef]"',
		'"ScalarRef[Undef]" constrains the referenced scalar value with "Undef"',
		'Value "bar" did not pass type constraint "Undef" (in ${$_})',
		'"Undef" is defined as: (!defined($_))',
	],
	'$UndefRef explanantion, given \"bar"',
);

is_deeply(
	(exception { $UndefRef->([]) })->explain,
	[
		'"ScalarRef[Undef]" is a subtype of "ScalarRef"',
		'Reference [] did not pass type constraint "ScalarRef"',
		'"ScalarRef" is defined as: (ref($_) eq \'SCALAR\' or ref($_) eq \'REF\')',
	],
	'$UndefRef explanantion, given []',
);

my $e_where = exception {
#line 1 "thisfile.plx"
package Monkey::Nuts;
"Error::TypeTiny"->throw(message => "Test");
};

#line 230 "exceptions.t"
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

BEGIN {
	package MyTypes;
	use Type::Library -base, -declare => qw(HttpMethod);
	use Type::Utils -all;
	use Types::Standard qw(Enum);
	
	declare HttpMethod,
		as Enum[qw/ HEAD GET POST PUT DELETE OPTIONS PATCH /],
		message { "$_ is not a HttpMethod" };
};

like(
	exception { MyTypes::HttpMethod->("FOOL") },
	qr{^FOOL is not a HttpMethod},
	"correct exception from type with null constraint",
);

{
	local $Type::Tiny::DD = sub { substr("$_[0]", 0, 5) };
	
	like(
		exception { Types::Standard::Str->([]) },
		qr{^ARRAY did not pass type constraint},
		"local \$Type::Tiny::DD",
	);
}

done_testing;
