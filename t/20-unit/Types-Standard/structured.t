=pod

=encoding utf-8

=head1 PURPOSE

Checks various values against structured types from Types::Standard.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib qw( . ./t ../inc ./inc );

use Test::More;
use Test::TypeTiny;

use Types::Standard -all, "slurpy";

my $struct1 = Map[Int, Num];

should_pass({1=>111,2=>222}, $struct1);
should_pass({1=>1.1,2=>2.2}, $struct1);
should_fail({1=>"Str",2=>222}, $struct1);
should_fail({1.1=>1,2=>2.2}, $struct1);

my $struct2 = Tuple[Int, Num, Optional([Int]), slurpy ArrayRef[Num]];
my $struct3 = Tuple[Int, Num, Optional[Int]];

should_pass([1, 1.1], $struct2);
should_pass([1, 1.1, 2], $struct2);
should_pass([1, 1.1, 2, 2.2], $struct2);
should_pass([1, 1.1, 2, 2.2, 2.3], $struct2);
should_pass([1, 1.1, 2, 2.2, 2.3, 2.4], $struct2);
should_fail({}, $struct2);
should_fail([], $struct2);
should_fail([1], $struct2);
should_fail([1.1, 1.1], $struct2);
should_fail([1, 1.1, 2.1], $struct2);
should_fail([1, 1.1, 2.1], $struct2);
should_fail([1, 1.1, 2, 2.2, 2.3, 2.4, "xyz"], $struct2);
should_fail([1, 1.1, undef], $struct2);
should_pass([1, 1.1], $struct3);
should_pass([1, 1.1, 2], $struct3);
should_fail([1, 1.1, 2, 2.2], $struct3);
should_fail([1, 1.1, 2, 2.2, 2.3], $struct3);
should_fail([1, 1.1, 2, 2.2, 2.3, 2.4], $struct3);
should_fail({}, $struct3);
should_fail([], $struct3);
should_fail([1], $struct3);
should_fail([1.1, 1.1], $struct3);
should_fail([1, 1.1, 2.1], $struct3);
should_fail([1, 1.1, 2.1], $struct3);
should_fail([1, 1.1, 2, 2.2, 2.3, 2.4, "xyz"], $struct3);
should_fail([1, 1.1, undef], $struct3);

my $struct4 = Dict[ name => Str, age => Int, height => Optional[Num] ];

should_pass({ name => "Bob", age => 40, height => 1.76 }, $struct4);
should_pass({ name => "Bob", age => 40 }, $struct4);
should_fail({ name => "Bob" }, $struct4);
should_fail({ age => 40 }, $struct4);
should_fail({ name => "Bob", age => 40.1 }, $struct4);
should_fail({ name => "Bob", age => 40, weight => 80.3 }, $struct4);
should_fail({ name => "Bob", age => 40, height => 1.76, weight => 80.3 }, $struct4);
should_fail({ name => "Bob", age => 40, height => "xyz" }, $struct4);
should_fail({ name => "Bob", age => 40, height => undef }, $struct4);
should_fail({ name => "Bob", age => undef, height => 1.76 }, $struct4);

my $opt1 = Optional[Int];
ok( $opt1->check(), "$opt1 check ()");
ok( $opt1->check(1), "$opt1 check (1)");
SKIP: {
	skip "`exists(\$_[0])` doesn't work properly in your version of Perl", 1
		if $] < 5.019004;
	ok(!$opt1->check(undef), "$opt1 check (undef)");
};
ok(!$opt1->check('xxx'), "$opt1 check ('xxx')");

my $slurper = Tuple[ArrayRef, slurpy Map[Num, Int]];

should_pass([ [], 1.1 => 1, 2.1 => 2 ], $slurper);
should_pass([ [] ], $slurper);
should_fail([ [], 1.1 => 1, xxx => 2 ], $slurper);
should_fail([ [], 1.1 => 1, 2.1 => undef ], $slurper);

my $struct5 = Dict[ i => Maybe[Int], b => Bool ];
should_pass({ i => 42, b => undef }, $struct5);
should_pass({ i => 42, b => '' }, $struct5);
should_pass({ i => 42, b => 0 }, $struct5);
should_pass({ i => 42, b => 1 }, $struct5);
should_pass({ i => undef, b => 1 }, $struct5);
should_fail({ b => 42, i => 1 }, $struct5);
should_fail({ i => 42 }, $struct5);
should_fail({ b => 1 }, $struct5);
should_fail({ i => 42, b => 1, a => 1 }, $struct5);
should_fail({ i => 42, a => 1 }, $struct5);
should_fail({ a => 42, b => 1 }, $struct5);

my $anyany = Tuple[Any, Any];

should_pass([1,1], $anyany);
should_pass([1,undef], $anyany);
should_pass([undef,undef], $anyany);
should_pass([undef,1], $anyany);
should_fail([1], $anyany);
should_fail([undef], $anyany);
should_fail([1,1,1], $anyany);
should_fail([1,1,undef], $anyany);

note "Tuple[] vs Tuple";
should_pass([ ], Tuple[]);
should_fail([1], Tuple[]);
should_pass([ ], Tuple);
should_pass([1], Tuple);

note "Dict[] vs Dict";
should_pass(+{      }, Dict[]);
should_fail(+{foo=>1}, Dict[]);
should_pass(+{      }, Dict);
should_pass(+{foo=>1}, Dict);

my $gazetteer = Dict[ foo => Int, bar => Optional[Int], slurpy HashRef[Num] ];
note "Dict[ ..., slurpy ... ]";
should_pass({ foo => 42 }, $gazetteer);
should_pass({ foo => 42, bar => 666 }, $gazetteer);
should_fail({ foo => 4.2 }, $gazetteer);
should_fail({ foo => 42, bar => 6.66 }, $gazetteer);
should_fail({ foo => 4.2, bar => 6.66 }, $gazetteer);
should_fail({ foo => undef }, $gazetteer);
should_fail({ }, $gazetteer);
should_pass({ foo => 42, baz => 999 }, $gazetteer);
should_pass({ foo => 42, bar => 666, baz => 999 }, $gazetteer);
should_fail({ foo => 4.2, baz => 999 }, $gazetteer);
should_fail({ foo => 42, bar => 6.66, baz => 999 }, $gazetteer);
should_fail({ foo => 4.2, bar => 6.66, baz => 999 }, $gazetteer);
should_fail({ foo => undef, baz => 999 }, $gazetteer);
should_fail({ baz => 999 }, $gazetteer);
should_pass({ foo => 42, baz => 9.99 }, $gazetteer);
should_pass({ foo => 42, bar => 666, baz => 9.99 }, $gazetteer);
should_fail({ foo => 4.2, baz => 9.99 }, $gazetteer);
should_fail({ foo => 42, bar => 6.66, baz => 9.99 }, $gazetteer);
should_fail({ foo => 4.2, bar => 6.66, baz => 9.99 }, $gazetteer);
should_fail({ foo => undef, baz => 9.99 }, $gazetteer);
should_fail({ baz => 9.99 }, $gazetteer);
should_fail({ foo => 42, baz => "x" }, $gazetteer);
should_fail({ foo => 42, bar => 666, baz => "x" }, $gazetteer);
should_fail({ foo => 4.2, baz => "x" }, $gazetteer);
should_fail({ foo => 42, bar => 6.66, baz => "x" }, $gazetteer);
should_fail({ foo => 4.2, bar => 6.66, baz => "x" }, $gazetteer);
should_fail({ foo => undef, baz => "x" }, $gazetteer);
should_fail({ baz => "x" }, $gazetteer);


done_testing;
