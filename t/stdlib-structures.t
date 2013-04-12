=pod

=encoding utf-8

=head1 PURPOSE

Checks various values against structured types from Types::Standard.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

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

my $opt1 = Optional[Int];
ok( $opt1->check(), "$opt1 check ()");
ok( $opt1->check(1), "$opt1 check (1)");
TODO: {
	local $TODO = "`exists \$arr[\$idx]` behaves oddly in all versions of Perl";
	ok(!$opt1->check(undef), "$opt1 check (undef)");
};
ok(!$opt1->check('xxx'), "$opt1 check ('xxx')");

done_testing;
